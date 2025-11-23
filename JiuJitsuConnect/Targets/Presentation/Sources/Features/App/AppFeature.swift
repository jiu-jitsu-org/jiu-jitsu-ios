import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct AppFeature {
    public init() { }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case splash(SplashFeature)
        case onboarding(OnboardingFeature)
        case main(MainFeature)
        case login(LoginFeature)
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
            state.destination = .main(.init(authInfo: authInfo))
            return .none
            
        default: return .none
        }
      }
      .ifLet(\.$destination, action: \.destination)
    }
}
