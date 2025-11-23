import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct MainFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        
        let authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case settings(SettingsFeature)
//        case profile(ProfileFeature)
    }
    
    @CasePathable
    public enum Action: Equatable {
        case settingsButtonTapped
        case profileButtonTapped
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingsButtonTapped:
                state.destination = .settings(.init(authInfo: state.authInfo))
                return .none
                
            case .profileButtonTapped:
//                state.destination = .profile(ProfileFeature.State())
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
