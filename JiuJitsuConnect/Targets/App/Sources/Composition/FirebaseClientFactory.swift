//
//  FirebaseClientFactory.swift
//  App
//
//  TCA `FirebaseClient` Dependency의 live 인스턴스 생성을 담당한다.
//  Firebase 초기화·푸시 권한 요청·FCM 토큰 송수신·로컬 캐시 등
//  Firebase 관련 부수효과(side effect)가 모두 이 한 파일에 모인다.
//
//  `DependencyContainer`는 본 파일이 만든 단일 인스턴스를 lazy 보유하여 재사용한다.
//

import CoreKit
import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Presentation

enum FirebaseClientFactory {

    private static let cacheKey = "jj.fcm.cached_token"
    /// 로그아웃·탈퇴 때 FCM 토큰 폐기가 실패했음(오프라인 등)을 남긴다(#269).
    private static let pendingDeletionKey = "jj.fcm.pending_token_deletion"

    /// Live `FirebaseClient`를 생성한다. `DependencyContainer.sharedFirebaseClient`에서 한 번만 호출된다.
    static func make() -> FirebaseClient {
        nonisolated(unsafe) let defaults = UserDefaults.standard

        return FirebaseClient(
            configure: {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            },
            requestPermission: {
                let center = UNUserNotificationCenter.current()
                do {
                    return try await center.requestAuthorization(options: [.alert, .badge, .sound])
                } catch {
                    return false
                }
            },
            getFCMToken: {
                let center = UNUserNotificationCenter.current()
                let settings = await center.notificationSettings()
                let granted: Bool
                switch settings.authorizationStatus {
                case .notDetermined:
                    do {
                        granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    } catch {
                        granted = false
                    }
                case .authorized, .provisional, .ephemeral:
                    granted = true
                default:
                    granted = false
                }
                guard granted else {
                    throw FirebaseError.permissionDenied
                }

                // 폐기하지 못한 토큰이 남아 있으면 먼저 폐기한다. SDK는 로컬 토큰만 지운 상태라,
                // 그대로 발급받으면 FCM이 같은 토큰을 돌려줘 새 계정에 이전 계정 토큰이 등록될 수 있다.
                // 폐기에 실패하면 발급도 하지 않는다 — 다음 시도(앱 진입·복귀·로그인)까지 이 기기는 푸시를 받지 않는다.
                try await deletePendingToken()

                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }

                _ = try await FirebaseAPNSTokenBridge.waitForDeviceToken()

                return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    Messaging.messaging().token { token, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(throwing: FirebaseError.tokenNotAvailable)
                        }
                    }
                }
            },
            retryPendingTokenDeletion: {
                guard defaults.bool(forKey: pendingDeletionKey) else { return }
                do {
                    try await deletePendingToken()
                } catch {
                    Log.trace("[FCM] 미뤄 둔 토큰 폐기 재시도 실패: \(error)", category: .system, level: .error)
                }
            },
            deleteFCMToken: {
                do {
                    try await deleteToken()
                    defaults.removeObject(forKey: pendingDeletionKey)
                } catch {
                    // 다음 토큰 발급(getFCMToken) 전에 다시 시도한다.
                    defaults.set(true, forKey: pendingDeletionKey)
                    throw error
                }
            },
            loadCachedToken: {
                defaults.string(forKey: cacheKey)
            },
            cacheToken: { token in
                defaults.set(token, forKey: cacheKey)
            },
            clearCachedToken: {
                defaults.removeObject(forKey: cacheKey)
            }
        )
    }

    private static let pendingDeletion = PendingDeletion()

    private static func deletePendingToken() async throws {
        try await pendingDeletion.run {
            let defaults = UserDefaults.standard
            guard defaults.bool(forKey: pendingDeletionKey) else { return }
            try await deleteToken()
            defaults.removeObject(forKey: pendingDeletionKey)
            // 폐기 전에 SDK 콜백이 캐시에 넣었을 수 있는 폐기된 토큰도 지운다.
            defaults.removeObject(forKey: cacheKey)
        }
    }

    private static func deleteToken() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Messaging.messaging().deleteToken { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

/// 미뤄 둔 폐기를 한 번에 하나만 돌린다. 앱 진입 재시도와 토큰 발급(getFCMToken)이 겹치면,
/// 늦게 끝난 폐기가 그 사이 새로 발급된 토큰을 지울 수 있다.
private actor PendingDeletion {
    private var tail: Task<Void, Error>?

    func run(_ operation: @Sendable @escaping () async throws -> Void) async throws {
        // 앞 폐기가 끝난 뒤 시작한다. 앞 폐기가 성공했으면 표시가 지워져 있어 operation은 바로 끝난다.
        let previous = tail
        let task = Task {
            _ = try? await previous?.value
            try await operation()
        }
        tail = task
        try await task.value
    }
}
