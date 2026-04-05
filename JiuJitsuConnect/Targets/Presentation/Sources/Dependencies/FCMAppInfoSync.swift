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
        do {
            let token = try await firebaseClient.getFCMToken()
            firebaseClient.cacheToken(token)
            try await registerAppInfo(fcmToken: token, userClient: userClient)
            Log.trace("✅ 앱 진입: FCM 발급 및 AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ 앱 진입: FCM 발급 실패 → 캐시 시도 (\(error))", category: .debug, level: .error)
            return await syncUsingCachedTokenIfAny(firebaseClient: firebaseClient, userClient: userClient, context: "앱 진입")
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
        do {
            let token = try await firebaseClient.getFCMToken()
            firebaseClient.cacheToken(token)
            try await registerAppInfo(fcmToken: token, userClient: userClient)
            Log.trace("✅ 로그인 후: FCM 재발급 및 AppInfo 반영", category: .network, level: .info)
            return true
        } catch {
            Log.trace("⚠️ 로그인 후: FCM 발급·AppInfo 모두 실패 (\(error))", category: .network, level: .error)
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

    private static func registerAppInfo(fcmToken: String, userClient: UserClient) async throws {
        let info = await MainActor.run {
            AppInfo.makeWithCurrentDevice(fcmToken: fcmToken)
        }
        try await userClient.registerAppInfo(info)
    }
}
