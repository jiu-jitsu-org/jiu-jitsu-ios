import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct AppFeature: Sendable {
    public init() { }
    
    @Reducer(state: .equatable)
    public enum Destination: Sendable {
        case splash(SplashFeature)
        case onboarding(OnboardingFeature)
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
        case destination(PresentationAction<Destination.Action>) // Associated value 'destination' of 'Sendable'-conforming enum 'Action' contains non-Sendable type 'AppFeature.Destination.Action'; this is an error in the Swift 6 language mode
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - Navigation Logic
            case .destination(.presented(.splash(.internal(.didFinishInitLaunch)))):
                state.destination = .login(.init())
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
        .ifLet(\.$destination, action: \.destination)
    }
}
