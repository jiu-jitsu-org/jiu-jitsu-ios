import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct AppFeature: Sendable {
    public init() { }

    private enum CancelID: Hashable, Sendable {
        // 푸시 탭 릴레이 구독. 앱 생명주기 내내 유지한다.
        case pushTapObserver
    }

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
        /// 자동 로그인으로 들어온 사람에게 홈 위에 덮어 보여주는 인사 장면. nil이면 장면 없이 홈만 보인다.
        var greeting: Greeting?

        public init() {}
    }

    /// 인사 장면 단계. 홈(AppTab)은 처음부터 만들어 두고 화면 아래에 숨겨 두었다가 `covering`에서 올라와 덮는다.
    public enum Greeting: Equatable, Sendable {
        case playing
        case covering
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case destination(PresentationAction<Destination.Action>)

        public enum ViewAction: Sendable {
            case onAppear
            /// 유니버설 링크 수신(`NSUserActivityTypeBrowsingWeb`).
            case deepLinkReceived(URL)
            /// 인사가 끝나 홈이 아래에서 올라오기 시작한다.
            case greetingCoverStarted
            /// 홈이 화면을 다 덮었다. 인사 장면을 걷어낸다.
            case greetingFinished
        }

        public enum InternalAction: Sendable {
            /// AppDelegate가 릴레이로 넘긴 푸시 탭 payload.
            case pushNotificationTapped(PushActionPayload)
        }
    }

    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.pushNotificationClient) var pushNotificationClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - DeepLink

            case .view(.onAppear):
                // 푸시 탭은 AppDelegate에서 오므로 View 이벤트가 아닌 릴레이 구독으로 받는다.
                // 콜드 스타트 탭은 릴레이가 보관했다가 이 구독에 바로 흘려준다.
                return .run { send in
                    for await payload in pushNotificationClient.taps() {
                        await send(.internal(.pushNotificationTapped(payload)))
                    }
                }
                .cancellable(id: CancelID.pushTapObserver, cancelInFlight: true)

            case let .view(.deepLinkReceived(url)):
                return Self.route(url, into: &state)

            case .view(.greetingCoverStarted):
                guard state.greeting != nil else { return .none }
                state.greeting = .covering
                return .none

            case .view(.greetingFinished):
                state.greeting = nil
                return .none

            case let .internal(.pushNotificationTapped(payload)):
                // 푸시 payload를 공유 링크와 같은 URL로 바꿔 동일 파이프라인에 태운다.
                // 미지원 type은 nil → 앱만 열린 채로 둔다(#28 미지원 값 처리).
                guard let url = PushActionRouter.makeURL(from: payload) else { return .none }
                return Self.route(url, into: &state)

                // MARK: - Navigation Logic

            case let .destination(.presented(.splash(.delegate(.finishedLaunch(authInfo))))):
                if let authInfo = authInfo {
                    state.destination = .appTab(.init(authInfo: authInfo))
                    // 공유 링크·푸시로 들어왔으면 그 글을 바로 보여줘야 해 인사를 건너뛴다
                    state.greeting = state.pendingDeepLink == nil ? .playing : nil
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

    /// 유니버설 링크·커스텀 스킴·푸시 탭이 모두 거치는 단일 진입점.
    private static func route(_ url: URL, into state: inout State) -> Effect<Action> {
        guard let link = DeepLinkParser.parse(url) else { return .none }
        // AppTab이 이미 살아 있으면 바로 흘려보내고, 스플래시·로그인 중이면 진입 직후 소비한다.
        guard case .appTab? = state.destination else {
            state.pendingDeepLink = link
            return .none
        }
        // 인사 중에 링크가 들어오면 인사를 접고 바로 그 화면을 보여준다
        state.greeting = nil
        return .send(.destination(.presented(.appTab(.deepLink(link)))))
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
