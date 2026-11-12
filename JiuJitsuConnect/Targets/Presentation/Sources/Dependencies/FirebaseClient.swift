//
//  FirebaseClient.swift
//  Data
//
//  Created by suni on 4/12/26.
//

import Foundation
import ComposableArchitecture

// MARK: - API Client Interface
public struct FirebaseClient {
    public var configure: @Sendable () -> Void
    public var requestPermission: @Sendable () async -> Bool
    public var getFCMToken: @Sendable () async throws -> String
    /// 로그아웃·탈퇴 때 폐기하지 못한 토큰(오프라인 등)이 있으면 다시 폐기한다. 로그인 여부와 관계없이 부른다(#269).
    public var retryPendingTokenDeletion: @Sendable () async -> Void
    public var deleteFCMToken: @Sendable () async throws -> Void
    public var loadCachedToken: @Sendable () -> String?
    public var cacheToken: @Sendable (String) -> Void
    public var clearCachedToken: @Sendable () -> Void

    public init(
        configure: @Sendable @escaping () -> Void,
        requestPermission: @Sendable @escaping () async -> Bool,
        getFCMToken: @Sendable @escaping () async throws -> String,
        retryPendingTokenDeletion: @Sendable @escaping () async -> Void,
        deleteFCMToken: @Sendable @escaping () async throws -> Void,
        loadCachedToken: @Sendable @escaping () -> String?,
        cacheToken: @Sendable @escaping (String) -> Void,
        clearCachedToken: @Sendable @escaping () -> Void
    ) {
        self.configure = configure
        self.requestPermission = requestPermission
        self.getFCMToken = getFCMToken
        self.retryPendingTokenDeletion = retryPendingTokenDeletion
        self.deleteFCMToken = deleteFCMToken
        self.loadCachedToken = loadCachedToken
        self.cacheToken = cacheToken
        self.clearCachedToken = clearCachedToken
    }
}

// MARK: - Live Implementation
extension FirebaseClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = Self(
        configure: {},
        requestPermission: { true },
        getFCMToken: { "test-fcm-token" },
        retryPendingTokenDeletion: {},
        deleteFCMToken: {},
        loadCachedToken: { nil },
        cacheToken: { _ in },
        clearCachedToken: {}
    )
}

// MARK: - Dependency Injection
public extension DependencyValues {
    var firebaseClient: FirebaseClient {
        get { self[FirebaseClient.self] }
        set { self[FirebaseClient.self] = newValue }
    }
}

extension FirebaseClient {
    static let unimplemented: Self = Self(
        configure: {
            fatalError("unimplemented.configure is not implemented")
        },
        requestPermission: {
            fatalError("unimplemented.requestPermission is not implemented")
        },
        getFCMToken: {
            fatalError("unimplemented.getFCMToken is not implemented")
        },
        retryPendingTokenDeletion: {
            fatalError("unimplemented.retryPendingTokenDeletion is not implemented")
        },
        deleteFCMToken: {
            fatalError("unimplemented.deleteFCMToken is not implemented")
        },
        loadCachedToken: {
            fatalError("unimplemented.loadCachedToken is not implemented")
        },
        cacheToken: { _ in
            fatalError("unimplemented.cacheToken is not implemented")
        },
        clearCachedToken: {
            fatalError("unimplemented.clearCachedToken is not implemented")
        }
    )
}

// MARK: - Firebase Errors
public enum FirebaseError: Error {
    case tokenNotAvailable
    case permissionDenied
}
