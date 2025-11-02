//
//  ProfileClent.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/1/25.
//

import ComposableArchitecture
import Domain

// MARK: - API Client Interface
public struct ProfileClent {
    public var postUser: @Sendable () async throws -> Domain.AuthInfo // 회원 가입
    
    public init(
        postUser: @Sendable @escaping () async throws -> Domain.AuthInfo
    ) {
        self.postUser = postUser
    }
}

// MARK: - Live Implementation
extension ProfileClent: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    public static let testValue: Self = Self(
        postUser: {
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
    var profileClent: ProfileClent {
        get { self[ProfileClent.self] }
        set { self[ProfileClent.self] = newValue }
    }
}

extension ProfileClent {
    static let unimplemented: Self = Self(
        postUser: {
            fatalError("AuthClient.serverLogin is not implemented")
        }
    )
}
