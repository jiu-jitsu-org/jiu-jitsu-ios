import ComposableArchitecture
import Domain

// MARK: - API Client Interface
public struct AuthClient {
    public var loginWithGoogle: @Sendable () async throws -> Domain.SNSUser
    public var loginWithApple: @Sendable () async throws -> Domain.SNSUser
    public var loginWithKakao: @Sendable () async throws -> Domain.SNSUser
    public var serverLogin: @Sendable (Domain.SNSUser) async throws -> Domain.AuthInfo
    public var serverLogout: @Sendable () async throws -> Bool
    public var autoLogin: @Sendable () async throws -> Domain.AuthInfo?
    public var hasValidToken: @Sendable () -> Bool
    
    public init(
        loginWithGoogle: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithApple: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithKakao: @Sendable @escaping () async throws -> Domain.SNSUser,
        serverLogin: @Sendable @escaping (Domain.SNSUser) async throws -> Domain.AuthInfo,
        serverLogout: @Sendable @escaping () async throws -> Bool,
        autoLogin: @Sendable @escaping () async throws -> Domain.AuthInfo?,
        hasValidToken: @Sendable @escaping () -> Bool
    ) {
        self.loginWithGoogle = loginWithGoogle
        self.loginWithApple = loginWithApple
        self.loginWithKakao = loginWithKakao
        self.serverLogin = serverLogin
        self.serverLogout = serverLogout
        self.autoLogin = autoLogin
        self.hasValidToken = hasValidToken
    }
}

// MARK: - Live Implementation
extension AuthClient: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    public static let testValue: Self = Self(
        loginWithGoogle: {
            Domain.SNSUser(accessToken: "testIdToken",
                           snsProvider: .google)
        },
        loginWithApple: {
            Domain.SNSUser(accessToken: "testIdToken",
                           snsProvider: .apple)
        },
        loginWithKakao: {
            Domain.SNSUser(accessToken: "testIdToken",
                           snsProvider: .kakao)
        },
        serverLogin: { _ in
            Domain.AuthInfo(accessToken: nil,
                            refreshToken: nil,
                            tempToken: "test-temp-token",
                            isNewUser: true,
                            userInfo: nil)
        },
        serverLogout: {
            true
        },
        autoLogin: {
            Domain.AuthInfo(accessToken: nil,
                            refreshToken: nil,
                            tempToken: "test-temp-token",
                            isNewUser: true,
                            userInfo: nil)
        },
        hasValidToken: {
            false
        }
    )
}

// MARK: - Dependency Injection
public extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

extension AuthClient {
    static let unimplemented: Self = Self(
        loginWithGoogle: {
            fatalError("AuthClient.loginWithGoogle is not implemented")
        },
        loginWithApple: {
            fatalError("AuthClient.loginWithApple is not implemented")
        },
        loginWithKakao: {
            fatalError("AuthClient.loginWithKakao is not implemented")
        },
        serverLogin: { _ in
            fatalError("AuthClient.serverLogin is not implemented")
        },
        serverLogout: {
            fatalError("AuthClient.serverLogout is not implemented")
        },
        autoLogin: {
            fatalError("AuthClient.autoLogin is not implemented")
        },
        hasValidToken: {
            fatalError("AuthClient.hasValidToken is not implemented")
        }
    )
}
