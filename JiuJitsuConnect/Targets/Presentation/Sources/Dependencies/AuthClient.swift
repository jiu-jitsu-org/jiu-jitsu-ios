import ComposableArchitecture
import Domain

public struct AuthClient {
    public var loginWithGoogle: @Sendable () async throws -> Domain.SNSUser
    public var loginWithApple: @Sendable () async throws -> Domain.SNSUser
    public var logout: @Sendable () async throws -> Void
    
    public init(loginWithGoogle: @Sendable @escaping () async throws -> Domain.SNSUser, loginWithApple: @Sendable @escaping () async throws -> Domain.SNSUser, logout: @Sendable @escaping () async throws -> Void) {
        self.loginWithGoogle = loginWithGoogle
        self.loginWithApple = loginWithApple
        self.logout = logout
    }
}

extension AuthClient: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    public static let testValue: Self = Self(
        loginWithGoogle: {
            Domain.SNSUser(id: "testId",
                           idToken: "textIdToken",
                           email: "test@test.com",
                           nickname: "test",
                           snsProvider: "GOOGLE")
        },
        loginWithApple: {
            Domain.SNSUser(id: "testId",
                           idToken: "textIdToken",
                           email: "test@test.com",
                           nickname: "test",
                           snsProvider: "APPLE")
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
        logout: {
            fatalError("AuthClient.logout is not implemented")
        }
    )
}
