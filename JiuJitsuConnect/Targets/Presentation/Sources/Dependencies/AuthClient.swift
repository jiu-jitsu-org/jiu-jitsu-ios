import ComposableArchitecture
import Domain

public struct AuthClient {
    public var loginWithGoogle: @Sendable () async throws -> Domain.SNSUser
    public var loginWithApple: @Sendable () async throws -> Domain.SNSUser
    public var loginWithKakao: @Sendable () async throws -> Domain.SNSUser
    public var appLogin: @Sendable (AuthRequest) async throws -> AuthResponse
    public var logout: @Sendable () async throws -> Void
    
    public init(loginWithGoogle: @Sendable @escaping () async throws -> Domain.SNSUser, loginWithApple: @Sendable @escaping () async throws -> Domain.SNSUser, loginWithKakao: @Sendable @escaping () async throws -> Domain.SNSUser, appLogin: @Sendable @escaping (AuthRequest) async throws -> AuthResponse, logout: @Sendable @escaping () async throws -> Void) {
        self.loginWithGoogle = loginWithGoogle
        self.loginWithApple = loginWithApple
        self.loginWithKakao = loginWithKakao
        self.appLogin = appLogin
        self.logout = logout
    }
}

extension AuthClient: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    public static let testValue: Self = Self(
        loginWithGoogle: {
            Domain.SNSUser(idToken: "textIdToken",
                           snsProvider: .google)
        },
        loginWithApple: {
            Domain.SNSUser(idToken: "textIdToken",
                           snsProvider: .apple)
        },
        loginWithKakao: {
            Domain.SNSUser(idToken: "textIdToken",
                           snsProvider: .kakao)
        },
        appLogin: { _ in
            Domain.AuthResponse(
                accessToken: "testAccessToken",
                refreshToken: "testRefreshToken",
                userInfo:
                    AuthResponse.UserInfo(
                        id: 0,
                        email: nil,
                        nickname: "test",
                        profileImageUrl: nil,
                        snsProvider: "APPLE",
                        deactivatedWithinGrace: false
                    )
                )
        },
        logout: { }
    )
}

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
        appLogin: { _ in
            fatalError("AuthClient.appLogin is not implemented")
        },
        logout: {
            fatalError("AuthClient.logout is not implemented")
        }
    )
}
