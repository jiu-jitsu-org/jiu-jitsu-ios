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

import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Presentation

enum FirebaseClientFactory {

    private static let cacheKey = "jj.fcm.cached_token"

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
            deleteFCMToken: {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    Messaging.messaging().deleteToken { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
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
}
