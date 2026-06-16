import ComposableArchitecture
import Domain

// MARK: - API Client Interface
public struct AuthClient {
    public var loginWithGoogle: @Sendable () async throws -> Domain.SNSUser
    public var loginWithApple: @Sendable () async throws -> Domain.SNSUser
    public var loginWithKakao: @Sendable () async throws -> Domain.SNSUser
    public var serverLogin: @Sendable (Domain.SNSUser) async throws -> Domain.AuthInfo
    public var serverLogout: @Sendable () async throws -> Bool
    public var signOut: @Sendable () async -> Void
    public var autoLogin: @Sendable () async throws -> Domain.AuthInfo?
    public var hasValidToken: @Sendable () -> Bool
    /// 웹뷰 토큰 만료 위임용 — 저장된 refresh 토큰으로 갱신 후 새 accessToken 반환.
    public var refreshSession: @Sendable () async throws -> String

    public init(
        loginWithGoogle: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithApple: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithKakao: @Sendable @escaping () async throws -> Domain.SNSUser,
        serverLogin: @Sendable @escaping (Domain.SNSUser) async throws -> Domain.AuthInfo,
        serverLogout: @Sendable @escaping () async throws -> Bool,
        signOut: @Sendable @escaping () async -> Void,
        autoLogin: @Sendable @escaping () async throws -> Domain.AuthInfo?,
        hasValidToken: @Sendable @escaping () -> Bool,
        refreshSession: @Sendable @escaping () async throws -> String
    ) {
        self.loginWithGoogle = loginWithGoogle
        self.loginWithApple = loginWithApple
        self.loginWithKakao = loginWithKakao
        self.serverLogin = serverLogin
        self.serverLogout = serverLogout
        self.signOut = signOut
        self.autoLogin = autoLogin
        self.hasValidToken = hasValidToken
        self.refreshSession = refreshSession
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
        signOut: {},
        autoLogin: {
            Domain.AuthInfo(accessToken: nil,
                            refreshToken: nil,
                            tempToken: "test-temp-token",
                            isNewUser: true,
                            userInfo: nil)
        },
        hasValidToken: {
            false
        },
        refreshSession: {
            "test-access-token"
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
            fatalError("unimplemented.loginWithGoogle is not implemented")
        },
        loginWithApple: {
            fatalError("unimplemented.loginWithApple is not implemented")
        },
        loginWithKakao: {
            fatalError("unimplemented.loginWithKakao is not implemented")
        },
        serverLogin: { _ in
            fatalError("unimplemented.serverLogin is not implemented")
        },
        serverLogout: {
            fatalError("unimplemented.serverLogout is not implemented")
        },
        signOut: {
            fatalError("unimplemented.signOut is not implemented")
        },
        autoLogin: {
            fatalError("unimplemented.autoLogin is not implemented")
        },
        hasValidToken: {
            fatalError("unimplemented.hasValidToken is not implemented")
        },
        refreshSession: {
            fatalError("unimplemented.refreshSession is not implemented")
        }
    )
}
