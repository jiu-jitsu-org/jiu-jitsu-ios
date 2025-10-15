import ComposableArchitecture
import Domain

// MARK: - API Client Interface
public struct AuthClient {
    public var loginWithGoogle: @Sendable () async throws -> Domain.SNSUser
    public var loginWithApple: @Sendable () async throws -> Domain.SNSUser
    public var loginWithKakao: @Sendable () async throws -> Domain.SNSUser
    public var serverLogin: @Sendable (Domain.SNSUser) async throws -> Domain.AuthInfo
    
    public init(
        loginWithGoogle: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithApple: @Sendable @escaping () async throws -> Domain.SNSUser,
        loginWithKakao: @Sendable @escaping () async throws -> Domain.SNSUser,
        serverLogin: @Sendable @escaping (Domain.SNSUser) async throws -> Domain.AuthInfo
    ) {
        self.loginWithGoogle = loginWithGoogle
        self.loginWithApple = loginWithApple
        self.loginWithKakao = loginWithKakao
        self.serverLogin = serverLogin
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
        }
    )
}
