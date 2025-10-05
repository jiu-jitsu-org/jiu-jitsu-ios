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
        
        @Presents public var destination: Destination.State?
        
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
        
        case destination(PresentationAction<Destination.Action>)
        
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        public enum Delegate: Equatable {
            case didLogin(SNSUser)
            case skipLogin // '둘러보기' 선택 시
        }
        case delegate(Delegate)
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case termsAgreement(TermsAgreementFeature)
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
                
//                if authResponse.isNewUser {
                    // ✅ 4. 신규 유저일 경우, destination 상태를 설정하여 바텀시트를 띄웁니다.
                    state.destination = .termsAgreement(.init())
//                } else {
                    // TODO: 기존 유저일 경우, 바로 로그인 완료 처리
                    // return .send(.delegate(.didLogin(authResponse)))
//                }
                return .none
                
            case ._serverLoginResponse(.failure):
                // TEST: - 임시 연결
                state.isLoading = false
                state.destination = .termsAgreement(.init())
                return .none
                
//            case let ._serverLoginResponse(.failure(error)):
//                state.isLoading = false
//                // TODO: 서버 로그인 실패 에러 처리 (토스트 등)
//                // 1. DisplayError를 받아옵니다.
//                guard let displayError = handleLoginError(error: error) else {
//                    // nil이 반환되면 (예: .signInCancelled) 아무것도 하지 않습니다.
//                    return .none
//                }
//                
//                // 2. DisplayError에 따라 상태를 업데이트하고 Effect를 반환합니다.
//                switch displayError {
//                case .toast(let message):
//                    let toastState = ToastState(message: message, style: .info)
//                    state.toast = toastState
//                    
//                    return .run { send in
//                        try await self.clock.sleep(for: toastState.duration)
//                        await send(.toastDismissed, animation: .default)
//                    }
//                    .cancellable(id: CancelID.toast)
//                    
//                default: return .none
//                }
                
                // MARK: - Destination 액션 처리
            case .destination(.presented(.termsAgreement(.delegate(.didAgree)))):
                // 약관 동의 완료 시 바텀시트를 닫고 다음 로직 수행
                state.destination = nil
                // TODO: 회원가입 완료 API 호출 또는 메인 화면으로 이동
                return .none
                
            case .destination:
                // .dismiss() 등 다른 presentation 액션 처리
                return .none
                
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
        .ifLet(\.$destination, action: \.destination)
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
