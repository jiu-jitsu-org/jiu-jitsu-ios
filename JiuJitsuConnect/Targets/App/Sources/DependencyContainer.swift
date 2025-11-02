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
    
    // MARK: - Repositories
    private lazy var authRepository: AuthRepository = AuthRepositoryImpl()
    
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
            }
        )
    }
    
}
