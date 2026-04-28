//
//  DependencyContainer.swift
//  App
//
//  Created by suni on 9/21/25.
//
//  앱의 Composition Root.
//  Repository / FirebaseClient 인스턴스 생명주기(lazy 단일 인스턴스)를 보유하고,
//  TCA Client(`AuthClient`, `UserClient`, `CommunityClient`, `FirebaseClient`) 빌드를 담당한다.
//
//  실제 인스턴스화 로직은 `RepositoryFactory` / `FirebaseClientFactory`로 분리되어 있어
//  본 컨테이너는 의존성 그래프를 조립하는 책임에만 집중한다.
//

import Foundation
import Domain
import Presentation
import CoreKit

public final class DependencyContainer {
    public static let shared = DependencyContainer()

    private init() {
        // 앱이 시작될 때, CoreKit의 Log 핸들러를 Pulse 핸들러로 설정합니다.
        Log.handler = PulseLogHandler()
    }

    // MARK: - Repositories (lazy single instance)
    private lazy var authRepository: AuthRepository = RepositoryFactory.makeAuthRepository()
    private lazy var userRepository: UserRepository = RepositoryFactory.makeUserRepository()
    private lazy var communityRepository: CommunityRepository = RepositoryFactory.makeCommunityRepository()

    // MARK: - Firebase Client (shared instance)
    private lazy var sharedFirebaseClient: FirebaseClient = FirebaseClientFactory.make()

    // MARK: - TCA Clients

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
            signOut: {
                await self.authRepository.signOut()
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
                self.sharedFirebaseClient.cacheToken(token)
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
        return sharedFirebaseClient
    }
}
