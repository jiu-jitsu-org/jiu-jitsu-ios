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
    
    private lazy var googleLoginUseCase = GoogleLoginUseCase(
        authRepository: authRepository
    )
    
    private lazy var logoutUseCase = LogoutUseCase(
        authRepository: authRepository
    )
    
    // MARK: - Public Methods
    
    public func configureAuthClient() -> AuthClient {
        return AuthClient(
            loginWithGoogle: { [weak self] in
                guard let self else { throw AuthError.dependencyNotFound }
                return try await self.googleLoginUseCase.execute()
            },
            logout: { [weak self] in
                guard let self else { throw AuthError.dependencyNotFound }
                try await self.logoutUseCase.execute()
            }
        )
    }
}
