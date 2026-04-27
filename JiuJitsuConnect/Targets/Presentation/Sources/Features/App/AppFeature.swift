import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct AppFeature: Sendable {
    public init() { }

    @Reducer
    public enum Destination {
        case splash(SplashFeature)
//        case onboarding(OnboardingFeature)
        case main(MainFeature)
        case appTab(AppTabFeature)
        case login(LoginFeature)
    }

    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State? = .splash(.init())

        public init() {}
    }

    public enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - Navigation Logic

            case let .destination(.presented(.splash(.delegate(.finishedLaunch(authInfo))))):
                if let authInfo = authInfo {
                    state.destination = .appTab(.init(authInfo: authInfo))
                    // 앱 진입 FCM sync: 로그인 상태일 때만 실행 (취소되지 않음)
                    return .run { _ in
                        await FCMAppInfoSync.syncOnAppLaunch(
                            firebaseClient: self.firebaseClient,
                            userClient: self.userClient
                        )
                    }
                } else {
                    state.destination = .login(.init())
                    return .none
                }

            case let .destination(.presented(.login(.delegate(.didLogin(authInfo))))):
                state.destination = .appTab(.init(authInfo: authInfo))
                // 로그인 성공 FCM sync
                return .run { _ in
                    await FCMAppInfoSync.syncAfterLoginSuccess(
                        firebaseClient: self.firebaseClient,
                        userClient: self.userClient
                    )
                }

            case .destination(.presented(.login(.delegate(.skipLogin)))):
                state.destination = .appTab(.init(authInfo: .guest))
                return .none

            default:
                return .none
            }
        }
        // ifLet runs AFTER parent logic to handle child state
        .ifLet(\.$destination, action: \.destination)
    }
}
// MARK: - Destination Conformances
extension AppFeature.Destination.State: Equatable {}
extension AppFeature.Destination.Action: Sendable {}
