import ComposableArchitecture
import Domain
import DesignSystem
import OSLog
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
        
        //        @Presents public var destination: Destination.State?
        
        public init() {}
    }
    
    @CasePathable
    public enum Action: Equatable {
        case kakaoButtonTapped
        case googleButtonTapped
        case appleButtonTapped
        case aroundButtonTapped
        
        case _socialLoginResponse(TaskResult<SNSUser>)
        case _serverLoginResponse(TaskResult<AuthInfo>)
        case _registerResponse(TaskResult<AuthInfo>)
        
        case sheet(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        public enum Delegate: Equatable {
            case didLogin(AuthInfo)
            case skipLogin
        }
        case delegate(Delegate)
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case nicknameSetting(NicknameSettingFeature)
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
                state.isLoading = false
                
                guard let domainError = error as? DomainError else {
                    Logger.network.error("Unknown login error: \(error)")
                    return .send(.showToast(.init(message: "알 수 없는 오류가 발생했습니다.", style: .info)))
                }
                
                switch domainError {
                case .signInCancelled:
                    return .none
                    
                // 2. 이 Feature가 문맥에 맞게 처리해야 하는 API 에러
                case .apiError(let code, _):
                    let message: String
                    switch code {
                    case .authenticationFailed, .wrongParameter:
                        message = code.displayMessage
                    default:
                        // .nicknameDuplicated 등 이 화면과 관련 없는 에러
                        Logger.network.error("Unhandled API Error in LoginFeature: \(code.rawValue)")
                        message = APIErrorCode.unknown.displayMessage
                    }
                    return .send(.showToast(.init(message: message, style: .info)))

                // 3. 그 외 모든 공통 에러는 DomainErrorMapper에게 위임
                default:
                    let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                    if case .toast(let message) = displayError {
                        return .send(.showToast(.init(message: message, style: .info)))
                    }
                    return .none
                }
                
            case let ._serverLoginResponse(.success(authInfo)):
                state.isLoading = false
                print(authInfo)
                // 1. 신규 유저일 경우
                if authInfo.isNewUser == true {
                    // tempToken 저장 후 약관 동의 Sheet 표시
                    guard let tempToken = authInfo.tempToken else {
                        Logger.debug.error("Temp Token is missing for new user.")
                        return .send(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info)))
                    }
                    state.tempToken = tempToken
                    state.sheet = .termsAgreement(.init())
                } else {
                    // 2. 기존 유저일 경우, 바로 로그인 완료 처리
                    Logger.debug.info("기존 유저 로그인 성공")
                    return .send(.delegate(.didLogin(authInfo)))
                }
                return .none
                
            case let ._serverLoginResponse(.failure(error)):
                state.isLoading = false
                guard let domainError = error as? DomainError else {
                    Logger.network.error("Unknown server login error: \(error)")
                    return .send(.showToast(.init(message: "알 수 없는 오류가 발생했습니다.", style: .info)))
                }
                
                switch domainError {
                // 1. 이 Feature가 문맥에 맞게 처리해야 하는 API 에러
                case .apiError(let code, _): // 캡처
                    let message: String
                    
                    switch code {
                    case .authenticationFailed, .wrongParameter:
                        message = code.displayMessage // 로컬 Fallback
                    default:
                        Logger.network.error("Unhandled API Error in LoginFeature: \(code.rawValue)")
                        message = APIErrorCode.unknown.displayMessage
                    }
                    return .send(.showToast(.init(message: message, style: .info)))

                // 2. 그 외 모든 공통 에러는 DomainErrorMapper에게 위임
                default:
                    let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                    if case .toast(let message) = displayError {
                        return .send(.showToast(.init(message: message, style: .info)))
                    }
                    return .none
                }
                
                // 약관 동의 완료 시 Sheet 닫고, NicknameSetting으로 Push
            case let .sheet(.presented(.termsAgreement(.delegate(.didFinishAgreement(isMarketingAgreed))))):
                guard let tempToken = state.tempToken else {
                    Logger.debug.error("Temp Token is missing.")
                    state.sheet = nil
                    return .send(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", style: .info)))
                }
                
                state.sheet = nil
                
                // path에 NicknameSettingFeature 상태 추가하여 push
                state.path.append(
                    .nicknameSetting(
                        .init(tempToken: tempToken, isMarketingAgreed: isMarketingAgreed)
                    )
                )
                return .none
                
                // MARK: - (수정) 최종 회원가입 결과 처리
            case let ._registerResponse(.success(authInfo)):
                state.isLoading = false
                state.path.removeAll() // 회원가입 성공 시 스택 초기화
                Logger.debug.info("회원가입 및 로그인 성공!")
                return .send(.delegate(.didLogin(authInfo)))
                
            case let ._registerResponse(.failure(error)):
                state.isLoading = false
                Logger.debug.error("회원가IP 실패: \(error.localizedDescription)")
                return .send(.showToast(.init(message: "회원가입에 실패했습니다. 다시 시도해주세요.", style: .info)))
                
                // MARK: - Path Reducer
            case let .path(action):
                switch action {
                    // 닉네임 설정 완료 시 최종 회원가입 API 호출
                case let .element(id: _, action: .nicknameSetting(.delegate(.didCompleteNicknameSetting(nickname, tempToken, isMarketingAgreed)))):
                    Logger.view.debug("""
                                    최종 회원가입 정보 취합 완료
                                    - Nickname: \(nickname)
                                    - TempToken: \(tempToken)
                                    - MarketingAgreed: \(isMarketingAgreed)
                                    """)
                    
                    // TODO: Dependency에 실제 register API 호출로 교체해야 합니다.
                    return .none
                    //                state.isLoading = true
                    //
                    //                return .run { send in
                    //                    await send(._registerResponse(
                    //                        await TaskResult {
                    //                            try await self.authClient.register(
                    //                                nickname: nickname,
                    //                                tempToken: tempToken,
                    //                                isMarketingAgreed: isMarketingAgreed
                    //                            )
                    //                        }
                    //                    ))
                    //                }
                default: return .none
                }
                
            case .sheet:
                return .none
                
                // MARK: - 토스트 관련 액션
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
                return .send(.delegate(.skipLogin))
                
            case .delegate:
                return .none
                
//                            default: return .none
            }
        }
        .ifLet(\.$sheet, action: \.sheet)
        .forEach(\.path, action: \.path)
    }
}
