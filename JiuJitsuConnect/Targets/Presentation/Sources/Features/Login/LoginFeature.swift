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
//        case _registerResponse(TaskResult<VoidSuccess>)
        case successRegister
        
        case sheet(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        public enum Delegate: Equatable {
            case didLogin(SNSUser) // TODO: 최종 로그인 완료 시 유저 정보 전달
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
                return .run { send in // Cannot infer contextual base in reference to member 'run'
                    await send(._socialLoginResponse( // Cannot infer contextual base in reference to member '_socialLoginResponse'
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
                    await send(._serverLoginResponse(
                        await TaskResult { try await self.authClient.serverLogin(user) }
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
                // 신규 유저일 경우, tempToken 저장 후 약관 동의 Sheet 표시
                state.tempToken = "dummy-temp-token-for-test"
                state.sheet = .termsAgreement(.init())
                //                } else {
                // TODO: 기존 유저일 경우, 바로 로그인 완료 처리
                // return .send(.delegate(.didLogin(authResponse)))
                //                }
                return .none
                
            case ._serverLoginResponse(.failure):
                state.isLoading = false
                // 테스트를 위한 임시 코드
                state.tempToken = "dummy-temp-token-for-test"
                state.sheet = .termsAgreement(.init())
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
                
                // 약관 동의 완료 시 Sheet 닫고, NicknameSetting으로 Push
            case let .sheet(.presented(.termsAgreement(.delegate(.didFinishAgreement(isMarketingAgreed))))):
                guard let tempToken = state.tempToken else {
                    // tempToken이 없으면 에러 처리
                    Logger.storage.error("Temp Token is missing.")
                    state.sheet = nil
                    return .send(.showToast(.init(message: "", style: .info)))
                }
                
                state.sheet = nil
                
                // path에 NicknameSettingFeature 상태 추가하여 push
                state.path.append(
                    .nicknameSetting(
                        .init(tempToken: tempToken, isMarketingAgreed: isMarketingAgreed)
                    )
                )
                return .none
                
                // 닉네임 설정 완료 시 최종 회원가입 API 호출
//            case let .path(.element(id: _, action: .nicknameSetting(.delegate(.didCompleteNicknameSetting(nickname, tempToken, isMarketingAgreed))))):
//                Logger.view.debug("""
//                    최종 회원가입 정보 취합 완료
//                    - Nickname: \(nickname)
//                    - TempToken: \(tempToken)
//                    - MarketingAgreed: \(isMarketingAgreed)
//                    """)
//                
//                state.isLoading = true
//                
//                return .run { send in
//                    try await self.clock.sleep(for: .seconds(1)) // API 호출 시뮬레이션
//                    await send(.successRegister)
//                }
                 
            case .successRegister:
                state.isLoading = false
                state.path.removeAll()
                Logger.view.debug("회원가입 및 로그인 성공!")
                return .none
                
//            case ._registerResponse(.success):
//                state.isLoading = false
//                state.path.removeAll() // 회원가입 성공 시 스택 초기화
//                // TODO: 로그인 성공 처리 (예: 메인 화면으로 이동)
//                Logger.view.debug("회원가입 및 로그인 성공!")
//                // return .send(.delegate(.didLogin(...)))
//                return .none
//                
//            case let ._registerResponse(.failure(error)):
//                state.isLoading = false
//                // TODO: 회원가입 실패 에러 처리
//                Logger.error.error("회원가입 실패: \(error.localizedDescription)")
//                return .send(.showToast(.init(message: "회원가입에 실패했습니다.", style: .error)))
                
                // MARK: - Path Reducer
            case .path:
                return .none
//            case let .path(action):
//                switch action {
//                case let .element(id: _, action: .nicknameSetting(.delegate(.didCompleteNicknameSetting(nickname, tempToken, isMarketingAgreed)))):
//                    Logger.view.debug("""
//                                        최종 회원가입 정보 취합 완료
//                                        - Nickname: \(nickname)
//                                        - TempToken: \(tempToken)
//                                        - MarketingAgreed: \(isMarketingAgreed)
//                                        """)
//                    
//                    state.isLoading = true
//                    
//                    return .run { send in
//                        try await self.clock.sleep(for: .seconds(1)) // API 호출 시뮬레이션
//                        await send(.successRegister)
//                    }
//                }
                
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
                
//            default: return .none
            }
        }
        .ifLet(\.$sheet, action: \.sheet)
        .forEach(\.path, action: \.path)
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
