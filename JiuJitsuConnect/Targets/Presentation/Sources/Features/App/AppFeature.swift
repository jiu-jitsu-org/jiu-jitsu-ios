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
        
        // TODO: - 설정화면 메인에 연결하고 여기서는 제거 필요.
        case settings(SettingsFeature)
        case signupComplete(SignupCompleteFeature)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State? = .splash(.init())
        // MARK: - View TEST
//        @Presents public var destination: Destination.State? = .signupComplete(.init(authInfo: AuthInfo(accessToken: nil, refreshToken: nil, tempToken: nil, isNewUser: true, userInfo: AuthInfo.UserInfo(userId: 0, email: nil, nickname: "주짓수 개잘해", profileImageUrl: nil, snsProvider: "KAKAO", deactivatedWithinGrace: false))))
        
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
