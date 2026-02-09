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
        return UserClient(
            signup: { info in
                try await self.userRepository.signup(info: info)
            },
            checkNickname: { info in
                try await self.userRepository.checkNickname(info: info)
            },
            withdrawal: {
                try await self.userRepository.withdrawal()
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
}
