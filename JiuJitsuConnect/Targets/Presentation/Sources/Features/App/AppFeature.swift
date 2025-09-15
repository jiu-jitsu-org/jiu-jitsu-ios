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
//        case .destination(.presented(.splash(.didFinishInitLaunch))):
//          state.destination = .onboarding(.init(isInit: true))
//          return .none
//          
//        case .destination(.presented(.splash(.didFinish(let isLogin)))):
//          state.destination = .mainTab(.init(isLogin: isLogin))
//          return .none
//          
//        case .destination(.presented(.onboarding(.didFinish))):
//          state.destination = .login(.init(isInit: true))
//          return .none
//          
//        case .destination(.presented(.login(.aroundTapped))):
//          state.destination = .mainTab(.init(isLogin: false))
//          return .none
//          
//        case .destination(.presented(.login(.successLogin(let isNewUser)))),
//             .destination(.presented(.mainTab(.successLogin(let isNewUser)))):
//          // TODO: - isNewUser가 true일 때 회원 가입 축하 화면 로직 추가 필요
//          state.destination = .main(.init(isLogin: true))
//          return .none
//          
//        case .destination(.presented(.main(.appReLaunch))):
//          state.destination = .splash(.init())
//          return .none
          
        case .destination:
          return .none
        default: return .none
        }
      }
      .ifLet(\.$destination, action: \.destination)
    }
}
