import ComposableArchitecture
import Domain

@Reducer
public struct LoginFeature {
    
    // MARK: - State & Action
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        // AlertState를 사용하여 에러 발생 시 알림창을 띄울 수 있습니다.
        @Presents public var alert: AlertState<Action.Alert>?
        
        public init() {}
    }
    
    @CasePathable
    public enum Action: Equatable {
        case kakaoButtonTapped
        case googleButtonTapped
        case appleButtonTapped
        case aroundButtonTapped
        
        // 비동기 로그인 결과 처리를 위한 내부 액션
//        case _loginResponse(TaskResult<SNSUser>)
        
        // 부모(AppFeature)에게 결과를 알리는 Delegate 액션
        public enum Delegate: Equatable {
            case didLogin(SNSUser)
            case skipLogin // '둘러보기' 선택 시
        }
        case delegate(Delegate)
        
        // Alert 관련 액션
        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable {}
    }
    
    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - 로그인 버튼 탭
            case .googleButtonTapped:
                state.isLoading = true
                return .run { _ in
                    let user = try await self.authClient.loginWithGoogle()
                    print("google login success \(user)")
                }
                
            case .appleButtonTapped:
                state.isLoading = true
                return .run { _ in
                    let user = try await self.authClient.loginWithApple()
                    print("user \(user)")
                }

            case .kakaoButtonTapped:
                state.isLoading = true
                return .run { _ in
                    let user = try await self.authClient.loginWithKakao()
                    print("user \(user)")
                }
                
            // MARK: - 로그인 결과 처리
//            case let ._loginResponse(.success(user)):
//                state.isLoading = false
//                // 부모에게 로그인 성공과 사용자 정보를 알림
//                return .send(.delegate(.didLogin(user)))
//                
//            case let ._loginResponse(.failure(error)):
//                state.isLoading = false
//                // 로그인 실패 시 에러 알림창 표시
//                state.alert = AlertState { TextState(error.localizedDescription) }
//                return .none
                
            // MARK: - 기타 액션
            case .aroundButtonTapped:
                // 부모에게 '둘러보기'를 선택했음을 알림
                return .send(.delegate(.skipLogin))
                
            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
