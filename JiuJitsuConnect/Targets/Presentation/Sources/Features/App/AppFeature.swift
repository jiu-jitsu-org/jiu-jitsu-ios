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
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - Navigation Logic
                
            case let .destination(.presented(.splash(.delegate(.finishedLaunch(authInfo))))):
                if let authInfo = authInfo {
                    // 자동 로그인 성공 → 탭바 화면으로
                    state.destination = .appTab(.init(authInfo: authInfo))
                } else {
                    // 자동 로그인 실패 or 토큰 없음 → 로그인 화면으로
                    state.destination = .login(.init())
                }
                return .none
                
            case let .destination(.presented(.login(.delegate(.didLogin(authInfo))))):
                state.destination = .appTab(.init(authInfo: authInfo))
                return .none
                
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
