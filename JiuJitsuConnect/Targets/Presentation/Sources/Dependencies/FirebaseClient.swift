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
    public var deleteFCMToken: @Sendable () async throws -> Void
    public var loadCachedToken: @Sendable () -> String?
    public var cacheToken: @Sendable (String) -> Void
    public var clearCachedToken: @Sendable () -> Void

    public init(
        configure: @Sendable @escaping () -> Void,
        requestPermission: @Sendable @escaping () async -> Bool,
        getFCMToken: @Sendable @escaping () async throws -> String,
        deleteFCMToken: @Sendable @escaping () async throws -> Void,
        loadCachedToken: @Sendable @escaping () -> String?,
        cacheToken: @Sendable @escaping (String) -> Void,
        clearCachedToken: @Sendable @escaping () -> Void
    ) {
        self.configure = configure
        self.requestPermission = requestPermission
        self.getFCMToken = getFCMToken
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
