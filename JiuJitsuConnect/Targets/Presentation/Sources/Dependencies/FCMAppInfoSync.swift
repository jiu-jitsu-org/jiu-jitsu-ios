//
//  FCMAppInfoSync.swift
//  Presentation
//

import CoreKit
import Domain
import Foundation

/// FCM 토큰 확보 후 `UserClient.registerAppInfo`까지 이어 주는 공통 로직
public enum FCMAppInfoSync: Sendable {
    /// 앱 콜드 스타트: Firebase 발급 우선 → 성공 시 저장 후 AppInfo, 실패 시 저장된 토큰으로 AppInfo 시도
    @discardableResult
    public static func syncOnAppLaunch(
        firebaseClient: FirebaseClient,
        userClient: UserClient
    ) async -> Bool {
        let token: String
        do {
            token = try await firebaseClient.getFCMToken()
            firebaseClient.cacheToken(token)
        } catch {
            Log.trace("⚠️ 앱 진입: FCM 발급 실패 → 캐시 시도 (\(error))", category: .debug, level: .error)
            return await syncUsingCachedTokenIfAny(firebaseClient: firebaseClient, userClient: userClient, context: "앱 진입")
        }

        do {
            try await registerAppInfo(fcmToken: token, userClient: userClient)
            Log.trace("✅ 앱 진입: FCM 발급 및 AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ 앱 진입: AppInfo 등록 실패 (\(error))", category: .network, level: .error)
            return false
        }
    }

    /// 로그인(자동/수동) 성공 직후: 캐시된 FCM이 있으면 AppInfo만, 없으면 Firebase 발급 후 AppInfo
    @discardableResult
    public static func syncAfterLoginSuccess(
        firebaseClient: FirebaseClient,
        userClient: UserClient
    ) async -> Bool {
        if let cached = firebaseClient.loadCachedToken(), !cached.isEmpty {
            do {
                try await registerAppInfo(fcmToken: cached, userClient: userClient)
                Log.trace("✅ 로그인 후: 캐시 FCM으로 AppInfo 반영", category: .network, level: .info)
                return true
            } catch {
                Log.trace("⚠️ 로그인 후: 캐시 FCM AppInfo 실패 (\(error))", category: .network, level: .error)
            }
        }

        let token: String
        do {
            token = try await firebaseClient.getFCMToken()
            firebaseClient.cacheToken(token)
        } catch {
            Log.trace("⚠️ 로그인 후: FCM 발급 실패 (\(error))", category: .debug, level: .error)
            return false
        }

        do {
            try await registerAppInfo(fcmToken: token, userClient: userClient)
            Log.trace("✅ 로그인 후: FCM 재발급 및 AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ 로그인 후: AppInfo 등록 실패 (\(error))", category: .network, level: .error)
            return false
        }
    }

    private static func syncUsingCachedTokenIfAny(
        firebaseClient: FirebaseClient,
        userClient: UserClient,
        context: String
    ) async -> Bool {
        guard let cached = firebaseClient.loadCachedToken(), !cached.isEmpty else {
            Log.trace("⚠️ \(context): 저장된 FCM 없음", category: .debug, level: .error)
            return false
        }
        do {
            try await registerAppInfo(fcmToken: cached, userClient: userClient)
            Log.trace("✅ \(context): 캐시 FCM으로 AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ \(context): 캐시 FCM AppInfo 실패 (\(error))", category: .network, level: .error)
            return false
        }
    }

    /// 앱이 켜져 있는 동안 바뀐 FCM 토큰 등록(#332). 토큰은 AppDelegate가 이미 캐시에 넣었다.
    @discardableResult
    public static func syncRefreshedToken(_ token: String, userClient: UserClient) async -> Bool {
        do {
            try await registerAppInfo(fcmToken: token, userClient: userClient)
            Log.trace("✅ FCM 토큰 교체 → AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ FCM 토큰 교체 AppInfo 실패 (\(error))", category: .network, level: .error)
            return false
        }
    }

    private static let inFlight = InFlightRegistrations()

    private static func registerAppInfo(fcmToken: String, userClient: UserClient) async throws {
        try await inFlight.run(token: fcmToken) {
            let info = await MainActor.run {
                AppInfo.makeWithCurrentDevice(fcmToken: fcmToken)
            }
            try await userClient.registerAppInfo(info)
        }
    }
}

/// 같은 토큰 등록이 진행 중이면 새로 보내지 않고 그 결과를 기다린다(#332).
/// 앱 진입·복귀·권한 허용·토큰 교체 등록이 같은 새 토큰으로 겹치면, 서버가 둘 다 "없는 토큰"으로 보고
/// 행을 두 개 만들어 푸시가 두 번 간다. 끝난 등록은 남기지 않는다 — 그다음 등록은 서버가 같은 토큰으로 알아본다.
private actor InFlightRegistrations {
    private var tasks: [String: Task<Void, Error>] = [:]

    func run(token: String, _ operation: @Sendable @escaping () async throws -> Void) async throws {
        while let running = tasks[token] {
            do {
                try await running.value
                return
            } catch {
                // 먼저 시작한 쪽이 취소됐으면(로그아웃, 복귀 연타) 이쪽이 취소되지 않은 한 직접 보낸다.
                guard running.isCancelled, !Task.isCancelled else { throw error }
                // 시작한 쪽의 정리보다 먼저 깨어날 수 있다. 끝난 Task를 다시 기다리며 돌지 않게 여기서 뺀다.
                if tasks[token] == running { tasks[token] = nil }
            }
        }
        let task = Task { try await operation() }
        tasks[token] = task
        defer {
            if tasks[token] == task { tasks[token] = nil }
        }
        // 시작한 Effect가 취소되면(로그아웃 등) 요청도 끊는다. 따로 띄운 Task라 저절로 취소되지 않는다.
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
