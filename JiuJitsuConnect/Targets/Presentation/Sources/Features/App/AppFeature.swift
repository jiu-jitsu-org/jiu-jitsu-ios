import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
    public enum State: Equatable {
        case splash(SplashFeature.State)
        case onboarding(OnboardingFeature.State)
        case auth(AuthFeature.State)
        case main(MainFeature.State)
    }
    
    public enum Action {
        case splash(SplashFeature.Action)
    }
    
    public var body: some ReducerOf<Self> {
        Scope(state: /State.splash, action: /Action.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
            // 스플래쉬의 Delegate 액션을 받아서 처리
            case let .splash(.delegate(.complete(result))):
                switch result {
                case .needsUpdate:
                    // TODO: 업데이트 팝업 노출 로직
                    return .none
                case .needsOnboarding:
                    state = .onboarding(OnboardingFeature.State())
                    return .none
                case .loginSuccess:
                    state = .main(MainFeature.State(isLoggedIn: true))
                    return .none
                case .loginFailure:
                    state = .main(MainFeature.State(isLoggedIn: false))
                    return .none
                }
            
            default:
                return .none
            }
        }
    }
}
