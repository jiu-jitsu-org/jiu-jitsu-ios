import ComposableArchitecture
import Domain
import DesignSystem

@Reducer
public struct LoginFeature {
    
    private enum CancelID { case toast }
    
    // MARK: - State & Action
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        public var toast: ToastState?
        
        public init() {}
    }
    
    @CasePathable
    public enum Action: Equatable {
        case kakaoButtonTapped
        case googleButtonTapped
        case appleButtonTapped
        case aroundButtonTapped
        
        case _socialLoginResponse(TaskResult<SNSUser>)
        case _serverLoginResponse(TaskResult<AuthResponse>)
        
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        public enum Delegate: Equatable {
            case didLogin(SNSUser)
            case skipLogin // '둘러보기' 선택 시
        }
        case delegate(Delegate)
    }
    
    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    @Dependency(\.continuousClock) var clock
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - 로그인 버튼 탭
            case .googleButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(._socialLoginResponse(
                        await TaskResult { try await self.authClient.loginWithGoogle() }
                    ))
                }
            case .appleButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(._socialLoginResponse(
                        await TaskResult { try await self.authClient.loginWithApple() }
                    ))
                }

            case .kakaoButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(._socialLoginResponse(
                        await TaskResult { try await self.authClient.loginWithKakao() }
                    ))
                }
                
            // MARK: - 로그인 결과 처리
            case let ._socialLoginResponse(.success(user)):
                return .run { send in
                    let request = AuthRequest(accessToken: user.accessToken, snsProvider: user.snsProvider)
                    await send(._serverLoginResponse(
                        await TaskResult { try await self.authClient.serverLogin(request) }
                    ))
                }
                
            case let ._socialLoginResponse(.failure(error)):
                state.isLoading = false
                // TODO: 서버 로그인 실패 에러 처리 (토스트 등)
                // 1. DisplayError를 받아옵니다.
                guard let displayError = handleLoginError(error: error) else {
                    // nil이 반환되면 (예: .signInCancelled) 아무것도 하지 않습니다.
                    return .none
                }
                
                // 2. DisplayError에 따라 상태를 업데이트하고 Effect를 반환합니다.
                switch displayError {
                case .toast(let message):
                    let toastState = ToastState(message: message, style: .info)
                    state.toast = toastState
                    
                    return .run { send in
                        try await self.clock.sleep(for: toastState.duration)
                        await send(.toastDismissed, animation: .default)
                    }
                    .cancellable(id: CancelID.toast)
                    
                default: return .none
                }
                
            case ._serverLoginResponse(.success):
                state.isLoading = false
                // TODO: 서버로부터 받은 accessToken 저장 및 로그인 완료 처리
                // return .send(.delegate(.didLogin(authResponse)))
                return .none

            case let ._serverLoginResponse(.failure(error)):
                state.isLoading = false
                // TODO: 서버 로그인 실패 에러 처리 (토스트 등)
                // 1. DisplayError를 받아옵니다.
                guard let displayError = handleLoginError(error: error) else {
                    // nil이 반환되면 (예: .signInCancelled) 아무것도 하지 않습니다.
                    return .none
                }
                
                // 2. DisplayError에 따라 상태를 업데이트하고 Effect를 반환합니다.
                switch displayError {
                case .toast(let message):
                    let toastState = ToastState(message: message, style: .info)
                    state.toast = toastState
                    
                    return .run { send in
                        try await self.clock.sleep(for: toastState.duration)
                        await send(.toastDismissed, animation: .default)
                    }
                    .cancellable(id: CancelID.toast)
                    
                default: return .none
                }
                
            case let .showToast(toastState):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.toastDismissed, animation: .default)
                }
                .cancellable(id: CancelID.toast)

            case .toastDismissed:
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .toastButtonTapped:
                return .send(.toastDismissed)
                
            // MARK: - 기타 액션
            case .aroundButtonTapped:
                // 부모에게 '둘러보기'를 선택했음을 알림
                return .send(.delegate(.skipLogin))
                
            case .delegate:
                return .none
            }
        }
    }
    
    private func handleLoginError(error: Error) -> DisplayError? {
        guard let domainError = error as? DomainError else {
            return .toast("알 수 없는 오류가 발생했습니다.")
        }
        
        // DomainError를 DisplayError로 변환
        let displayError = DomainErrorMapper.toDisplayError(from: domainError)
        
        // .none 케이스는 nil을 반환하여 UI 변경이 없음을 알림
        if case .none = displayError {
            return nil
        }
        
        return displayError
    }
}
