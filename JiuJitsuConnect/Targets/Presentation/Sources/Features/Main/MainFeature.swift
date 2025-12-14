import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct MainFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        @Presents var loginModal: LoginFeature.State?
        
        var authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    @Reducer(state: .equatable, action: .equatable, .sendable)
    public enum Destination {
        case settings(SettingsFeature)
//        case profile(ProfileFeature)
    }
    
    @CasePathable
    public enum Action: Equatable, Sendable {
        case settingsButtonTapped
        case profileButtonTapped
        
        case showLoginModal
        
        // 네비게이션 액션
        case loginModal(PresentationAction<LoginFeature.Action>)
        case destination(PresentationAction<Destination.Action>)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingsButtonTapped:
                if state.authInfo.isGuest {
                    return .send(.showLoginModal)
                } else {
                    state.destination = .settings(.init(authInfo: state.authInfo))
                    return .none
                }
                
            case .profileButtonTapped:
                if state.authInfo.isGuest {
                    return .send(.showLoginModal)
                } else {
                    state.destination = .settings(.init(authInfo: state.authInfo))
                    return .none
                }
                
                // MARK: - Login Logic
            case .showLoginModal:
                state.loginModal = LoginFeature.State()
                return .none
                
            case let .loginModal(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo):
                    state.authInfo = newAuthInfo
                    
                    if case var .settings(settingsState) = state.destination {
                        settingsState.authInfo = newAuthInfo
                        state.destination = .settings(settingsState)
                    }
                    state.loginModal = nil
                    return .none
                    
                case .skipLogin:
                    state.loginModal = nil
                    return .none
                }
                
            case .loginModal:
                return .none
                
            case let .destination(.presented(.settings(.delegate(delegateAction)))):
                switch delegateAction {
                case .didLogoutSuccessfully:
                    state.authInfo = .guest
                    state.destination = nil
                    
                    return .none
                    
                case .didWithdrawSuccessfully:
                    state.authInfo = .guest
                    state.destination = nil
                    
                    return .send(.showLoginModal)
                }
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$loginModal, action: \.loginModal) {
            LoginFeature()
        }
    }
}
