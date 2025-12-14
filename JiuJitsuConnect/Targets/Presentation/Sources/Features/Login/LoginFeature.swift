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
        case kakaoButtonTapped
        case googleButtonTapped
        case appleButtonTapped
        case aroundButtonTapped
        
        case _socialLoginResponse(TaskResult<SNSUser>)
        case _serverLoginResponse(TaskResult<AuthInfo>)
        
        case sheet(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        public enum Delegate: Equatable, Sendable {
            case didLogin(AuthInfo)
            case skipLogin
        }
        case delegate(Delegate)
    }
    
    @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
    public enum Path {
        case nicknameSetting(NicknameSettingFeature)
        case signupComplete(SignupCompleteFeature)
    }
    
    @Reducer(state: .equatable, action: .equatable, .sendable)
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
                        await TaskResult { try await authClient.loginWithGoogle() }
                    ))
                }
                
            case .appleButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(._socialLoginResponse(
                        await TaskResult { try await authClient.loginWithApple() }
                    ))
                }
                
            case .kakaoButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(._socialLoginResponse(
                        await TaskResult { try await authClient.loginWithKakao() }
                    ))
                }
                
                // MARK: - 로그인 결과 처리
            case let ._socialLoginResponse(.success(user)):
                return .run { send in
                    await send(._serverLoginResponse(
                        await TaskResult { try await authClient.serverLogin(user) }
                    ))
                }
                
            case let ._socialLoginResponse(.failure(error)):
                return handleLoginError(state: &state, error: error)
                
            case let ._serverLoginResponse(.success(authInfo)):
                state.isLoading = false
                print(authInfo)
                // 1. 신규 유저일 경우
                if authInfo.isNewUser == true {
                    guard let tempToken = authInfo.tempToken else {
                        Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                        return .send(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info)))
                    }
                    state.tempToken = tempToken
                    state.sheet = .termsAgreement(.init())
                } else {
                    // 2. 기존 유저일 경우
                    Log.trace("기존 유저 로그인 성공", category: .debug, level: .info)
                    return .send(.delegate(.didLogin(authInfo)))
                }
                return .none
                
            case let ._serverLoginResponse(.failure(error)):
                return handleLoginError(state: &state, error: error)
                
                // 약관 동의 완료
            case let .sheet(.presented(.termsAgreement(.delegate(.didFinishAgreement(isMarketingAgreed))))):
                guard let tempToken = state.tempToken else {
                    Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                    state.sheet = nil
                    return .send(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info)))
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
                    return .send(.showToast(.init(message: message, style: .info, bottomPadding: 72)))
                    
                default: return .none
                }
                
            case .sheet:
                return .none
                
                // MARK: - 토스트 관련 액션
            case let .showToast(toastState):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.toastDismissed)
                }
                .cancellable(id: CancelID.toast)
                
            case .toastDismissed:
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .toastButtonTapped:
                return .send(.toastDismissed)
                
                // MARK: - 기타 액션
            case .aroundButtonTapped:
                return .send(.delegate(.skipLogin))
                
            case .delegate:
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
                return .send(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info)))
            }
            
            switch domainError {
            case .signInCancelled:
                return .none
                
            case .apiError(let code, _):
                let message: String  = code.displayMessage
                return .send(.showToast(.init(message: message, style: .info)))

            default:
                // 그 외 모든 공통 에러는 DomainErrorMapper에게 위임
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.showToast(.init(message: message, style: .info)))
                }
                return .none
            }
        }
}
