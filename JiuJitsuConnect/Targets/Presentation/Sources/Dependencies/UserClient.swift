//
//  UserClient.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/1/25.
//

import ComposableArchitecture
import Domain

// MARK: - API Client Interface
public struct UserClient {
    public var signup: @Sendable (Domain.SignupInfo) async throws -> Domain.AuthInfo // 회원 가입
    
    public init(
        signup: @Sendable @escaping (Domain.SignupInfo) async throws -> Domain.AuthInfo
    ) {
        self.signup = signup
    }
}

// MARK: - Live Implementation
extension UserClient: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    public static let testValue: Self = Self(
        signup: { _ in
            Domain.AuthInfo(accessToken: nil,
                            refreshToken: nil,
                            tempToken: "test-temp-token",
                            isNewUser: true,
                            userInfo: nil)
        }
    )
}

// MARK: - Dependency Injection
public extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

extension UserClient {
    static let unimplemented: Self = Self(
        signup: { _ in
            fatalError("unimplemented.signup is not implemented")
        }
    )
}
