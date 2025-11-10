import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
    public init() { }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case splash(SplashFeature)
        case onboarding(OnboardingFeature)
        case main(MainFeature)
        case login(LoginFeature)
        
        // TODO: - 설정화면 메인에 연결하고 여기서는 제거 필요.
        case settings(SettingsFeature)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State? = .splash(.init())
        
        public init() {}
    }
    
    @CasePathable
    public enum Action {
        case destination(PresentationAction<Destination.Action>)
    }
    
    public var body: some ReducerOf<Self> {
      Reduce { state, action in
        switch action {
        case .destination(.presented(.splash(.didFinishInitLaunch))):
            state.destination = .login(.init())
          return .none
            
        case let .destination(.presented(.login(.delegate(.didLogin(authInfo))))):
            state.destination = .settings(.init(authInfo: authInfo))
            return .none
            
        default: return .none
        }
      }
      .ifLet(\.$destination, action: \.destination)
    }
}
