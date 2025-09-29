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

@MainActor
public final class DependencyContainer {
    public static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Use Cases
    private lazy var authRepository: AuthRepository = AuthRepositoryImpl()
    
    private lazy var googleLoginUseCase = GoogleLoginUseCase(authRepository: authRepository)
    private lazy var appleLoginUseCase = AppleLoginUseCase(authRepository: authRepository)
    private lazy var kakaoLoginUseCase = KakaoLoginUseCase(authRepository: authRepository)
    
    private lazy var serverLoginUseCase = AppLoginUseCase(authRepository: authRepository)
    
    private lazy var logoutUseCase = LogoutUseCase(
        authRepository: authRepository
    )
    
    // MARK: - Public Methods
    
    public func configureAuthClient() -> AuthClient {
        return AuthClient(
            loginWithGoogle: { [weak self] in
                try await self?.googleLoginUseCase.execute() ?? { throw AuthError.dependencyNotFound }()
            },
            loginWithApple: { [weak self] in
                try await self?.appleLoginUseCase.execute() ?? { throw AuthError.dependencyNotFound }()
            },
            loginWithKakao: { [weak self] in
                try await self?.kakaoLoginUseCase.execute() ?? { throw AuthError.dependencyNotFound }()
            },
            appLogin: { [weak self] request in
                try await self?.serverLoginUseCase.execute(request: request) ?? { throw AuthError.dependencyNotFound }()
            },
            logout: { [weak self] in
                try await self?.logoutUseCase.execute() ?? { throw AuthError.dependencyNotFound }()
            }
        )
    }
}
