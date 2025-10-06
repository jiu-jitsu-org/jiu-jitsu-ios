//
//  GoogleLoginUseCase.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public final class GoogleLoginUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws -> SNSUser {
        return try await authRepository.signInWithGoogle()
    }
}

public final class AppleLoginUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws -> SNSUser {
        return try await authRepository.signInWithApple()
    }
}
public final class KakaoLoginUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws -> SNSUser {
        return try await authRepository.signInWithKakao()
    }
}

public final class LogoutUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws {
        try await authRepository.signOut()
    }
}

public final class ServerLoginUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute(user: SNSUser) async throws -> AuthInfo {
        return try await authRepository.serverLogin(user: user)
    }
}
