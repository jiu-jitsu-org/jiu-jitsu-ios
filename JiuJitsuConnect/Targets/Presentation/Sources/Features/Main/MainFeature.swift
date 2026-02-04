import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct MainFeature: Sendable {
    public init() {}
    
    @Reducer
    public enum Destination {
        case settings(SettingsFeature)
        //        case profile(ProfileFeature)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Presents public var loginModal: LoginFeature.State?
        
        public var authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        
        // 네비게이션 액션
        case loginModal(PresentationAction<LoginFeature.Action>)
        case destination(PresentationAction<Destination.Action>)
        
        public enum ViewAction: Sendable {
            case settingsButtonTapped
            case profileButtonTapped
        }
        
        public enum InternalAction: Sendable {
            case showLoginModal
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.settingsButtonTapped):
                if state.authInfo.isGuest {
                    return .send(.internal(.showLoginModal))
                } else {
                    state.destination = .settings(.init(authInfo: state.authInfo))
                    return .none
                }
                
            case .view(.profileButtonTapped):
                if state.authInfo.isGuest {
                    return .send(.internal(.showLoginModal))
                } else {
                    state.destination = .settings(.init(authInfo: state.authInfo))
                    return .none
                }
                
                // MARK: - Login Logic
            case .internal(.showLoginModal):
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
                    
                    return .send(.internal(.showLoginModal))
                }
                
            case .destination, .view, .internal:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$loginModal, action: \.loginModal) {
            LoginFeature()
        }
    }
}
extension MainFeature.Destination.State: Equatable {}
extension MainFeature.Destination.Action: Sendable {}
