import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct LoginFeature {
    
    private enum CancelID { case toast }
    
    // MARK: - State & Action
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        public var toast: ToastState?
        
        var tempToken: String?
        
        @Presents var sheet: Destination.State?
        var path = StackState<Path.State>()
        
        public init() {}
    }
    
    @CasePathable
    public enum Action: Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        case sheet(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        
        public enum ViewAction: Equatable, Sendable {
            case kakaoButtonTapped
            case googleButtonTapped
            case appleButtonTapped
            case aroundButtonTapped
            case toastButtonTapped(ToastState.Action)
        }
        
        public enum InternalAction: Equatable, Sendable {
            case socialLoginResponse(TaskResult<SNSUser>)
            case serverLoginResponse(TaskResult<AuthInfo>)
            case showToast(ToastState)
            case toastDismissed
        }
        
        public enum DelegateAction: Equatable, Sendable {
            case didLogin(AuthInfo)
            case skipLogin
        }
    }
    
    public enum Path: Equatable, Sendable {
        case nicknameSetting(NicknameSettingFeature)
        case signupComplete(SignupCompleteFeature)
    }
    
    public enum Destination: Equatable, Sendable {
        case termsAgreement(TermsAgreementFeature)
    }
    
    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    @Dependency(\.continuousClock) var clock
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // MARK: - 로그인 버튼 탭
            case .view(.googleButtonTapped):
                state.isLoading = true
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithGoogle() }
                    )))
                }
                
            case .view(.appleButtonTapped):
                state.isLoading = true
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithApple() }
                    )))
                }
                
            case .view(.kakaoButtonTapped):
                state.isLoading = true
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithKakao() }
                    )))
                }
                
                // MARK: - 로그인 결과 처리
            case let .internal(.socialLoginResponse(.success(user))):
                return .run { send in
                    await send(.internal(.serverLoginResponse(
                        await TaskResult { try await authClient.serverLogin(user) }
                    )))
                }
                
            case let .internal(.socialLoginResponse(.failure(error))):
                return handleLoginError(state: &state, error: error)
                
            case let .internal(.serverLoginResponse(.success(authInfo))):
                state.isLoading = false
                print(authInfo)
                // 1. 신규 유저일 경우
                if authInfo.isNewUser == true {
                    guard let tempToken = authInfo.tempToken else {
                        Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                        return .send(.internal(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info))))
                    }
                    state.tempToken = tempToken
                    state.sheet = .termsAgreement(.init())
                } else {
                    // 2. 기존 유저일 경우
                    Log.trace("기존 유저 로그인 성공", category: .debug, level: .info)
                    return .send(.delegate(.didLogin(authInfo)))
                }
                return .none
                
            case let .internal(.serverLoginResponse(.failure(error))):
                return handleLoginError(state: &state, error: error)
                
                // 약관 동의 완료
            case let .sheet(.presented(.termsAgreement(.delegate(.didFinishAgreement(isMarketingAgreed))))):
                guard let tempToken = state.tempToken else {
                    Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                    state.sheet = nil
                    return .send(.internal(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info))))
                }
                
                state.sheet = nil
                state.path.append(
                    .nicknameSetting(
                        .init(tempToken: tempToken, isMarketingAgreed: isMarketingAgreed)
                    )
                )
                return .none
                
                // MARK: - Path Reducer
            case let .path(action):
                switch action {
                    // 닉네임 설정 완료
                case let .element(id: _, action: .nicknameSetting(.delegate(.signupSuccessful(info)))):
                    state.path.append(.signupComplete(.init(authInfo: info)))
                    return .none
                    
                    // 회원가입 완료 확인
                case let .element(id: _, action: .signupComplete(.delegate(.completeSignupFlow(info)))):
                    return .send(.delegate(.didLogin(info)))
                    
                    // 닉네임 설정 실패
                case let .element(id: _, action: .nicknameSetting(.delegate(.signupFailed(message)))):
                    return .send(.internal(.showToast(.init(message: message, style: .info, bottomPadding: 72))))
                    
                default: return .none
                }
                
            case .sheet:
                return .none
                
                // MARK: - 토스트 관련 액션
            case let .internal(.showToast(toastState)):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.internal(.toastDismissed))
                }
                .cancellable(id: CancelID.toast)
                
            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))
                
                // MARK: - 기타 액션
            case .view(.aroundButtonTapped):
                return .send(.delegate(.skipLogin))
                
            case .delegate, .view, .internal:
                return .none
            }
        }
        .ifLet(\.$sheet, action: \.sheet)
        .forEach(\.path, action: \.path)
    }
    
    private func handleLoginError(state: inout State, error: Error) -> Effect<Action> {
            state.isLoading = false
            
            guard let domainError = error as? DomainError else {
                Log.trace("Unknown login error: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
            }
            
            switch domainError {
            case .signInCancelled:
                return .none
                
            case .apiError(let code, _):
                let message: String  = code.displayMessage
                return .send(.internal(.showToast(.init(message: message, style: .info))))

            default:
                // 그 외 모든 공통 에러는 DomainErrorMapper에게 위임
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.internal(.showToast(.init(message: message, style: .info))))
                }
                return .none
            }
        }
}
