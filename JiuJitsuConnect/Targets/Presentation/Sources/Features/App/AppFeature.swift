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
        case appTab(AppTabFeature)
        case login(LoginFeature)
    }

    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State? = .splash(.init())
        // 스플래시·로그인 중에 들어온 딥링크 보관소. AppTab이 만들어지는 즉시 소비한다.
        var pendingDeepLink: DeepLink?

        public init() {}
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case destination(PresentationAction<Destination.Action>)

        public enum ViewAction: Sendable {
            /// 유니버설 링크 수신(`NSUserActivityTypeBrowsingWeb`).
            case deepLinkReceived(URL)
        }
    }

    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - DeepLink

            case let .view(.deepLinkReceived(url)):
                guard let link = DeepLinkParser.parse(url) else { return .none }
                // AppTab이 이미 살아 있으면 바로 흘려보내고, 스플래시·로그인 중이면 진입 직후 소비한다.
                guard case .appTab? = state.destination else {
                    state.pendingDeepLink = link
                    return .none
                }
                return .send(.destination(.presented(.appTab(.deepLink(link)))))

                // MARK: - Navigation Logic

            case let .destination(.presented(.splash(.delegate(.finishedLaunch(authInfo))))):
                if let authInfo = authInfo {
                    state.destination = .appTab(.init(authInfo: authInfo))
                    // 앱 진입 FCM sync: 로그인 상태일 때만 실행 (취소되지 않음)
                    return .merge(
                        Self.consumePendingDeepLink(&state),
                        .run { _ in
                            await FCMAppInfoSync.syncOnAppLaunch(
                                firebaseClient: self.firebaseClient,
                                userClient: self.userClient
                            )
                        }
                    )
                } else if state.pendingDeepLink != nil {
                    // 공유 링크로 들어온 비로그인 사용자. 게시글 상세는 비로그인 접근 가능 정책이라
                    // 로그인 화면을 세우지 않고 게스트로 바로 글을 보여준다.
                    state.destination = .appTab(.init(authInfo: .guest))
                    return Self.consumePendingDeepLink(&state)
                } else {
                    state.destination = .login(.init())
                    return .none
                }

            case let .destination(.presented(.login(.delegate(.didLogin(authInfo))))):
                state.destination = .appTab(.init(authInfo: authInfo))
                // 로그인 성공 FCM sync
                return .merge(
                    Self.consumePendingDeepLink(&state),
                    .run { _ in
                        await FCMAppInfoSync.syncAfterLoginSuccess(
                            firebaseClient: self.firebaseClient,
                            userClient: self.userClient
                        )
                    }
                )

            case .destination(.presented(.login(.delegate(.skipLogin)))):
                state.destination = .appTab(.init(authInfo: .guest))
                return Self.consumePendingDeepLink(&state)

            default:
                return .none
            }
        }
        // ifLet runs AFTER parent logic to handle child state
        .ifLet(\.$destination, action: \.destination)
    }

    /// 보관 중인 딥링크가 있으면 방금 만들어진 AppTab으로 흘려보낸다.
    private static func consumePendingDeepLink(_ state: inout State) -> Effect<Action> {
        guard let link = state.pendingDeepLink else { return .none }
        state.pendingDeepLink = nil
        return .send(.destination(.presented(.appTab(.deepLink(link)))))
    }
}
// MARK: - Destination Conformances
extension AppFeature.Destination.State: Equatable {}
extension AppFeature.Destination.Action: Sendable {}
