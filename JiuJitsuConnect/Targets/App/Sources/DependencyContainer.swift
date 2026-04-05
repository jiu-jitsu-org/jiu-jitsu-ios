//
//  DependencyContainer.swift
//  App
//
//  Created by suni on 9/21/25.
//

import Foundation
import Domain
import Data
import Presentation
import ComposableArchitecture
import CoreKit
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

public final class DependencyContainer {
    public static let shared = DependencyContainer()
    
    private init() {
        // 앱이 시작될 때, CoreKit의 Log 핸들러를 Pulse 핸들러로 설정합니다.
        Log.handler = PulseLogHandler()
    }
    
    // MARK: - Repositories
    private lazy var authRepository: AuthRepository = AuthRepositoryImpl()
    private lazy var userRepository: UserRepository = UserRepositoryImpl()
    private lazy var communityRepository: CommunityRepository = CommunityRepositoryImpl()
    
    // MARK: - Public Methods
    
    public func configureAuthClient() -> AuthClient {
        return AuthClient(
            loginWithGoogle: {
                try await self.authRepository.signInWithGoogle()
            },
            loginWithApple: {
                try await self.authRepository.signInWithApple()
            },
            loginWithKakao: {
                try await self.authRepository.signInWithKakao()
            },
            serverLogin: { user in
                try await self.authRepository.serverLogin(user: user)
            },
            serverLogout: {
                try await self.authRepository.serverLogout()
            },
            autoLogin: {
                try await self.authRepository.autoLogin()
            },
            hasValidToken: {
                self.authRepository.hasValidToken()
            }
        )
    }
    
    public func configureUserClient() -> UserClient {
        UserClient(
            signup: { info in
                try await self.userRepository.signup(info: info)
            },
            checkNickname: { info in
                try await self.userRepository.checkNickname(info: info)
            },
            withdrawal: {
                try await self.userRepository.withdrawal()
            },
            registerAppInfo: { info in
                _ = try await self.userRepository.registerAppInfo(info: info)
            },
            updateFCMToken: { token in
                let info = await MainActor.run {
                    AppInfo.makeWithCurrentDevice(fcmToken: token)
                }
                _ = try await self.userRepository.registerAppInfo(info: info)
            }
        )
    }
    
    public func configureCommunityClient() -> CommunityClient {
        return CommunityClient(
            fetchProfile: {
                try await self.communityRepository.fetchProfile()
            },
            updateProfile: { profile, section in
                try await self.communityRepository.updateProfile(profile, section: section)
            }
        )
    }

    public func configureFirebaseClient() -> FirebaseClient {
        let cacheKey = "jj.fcm.cached_token"
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
