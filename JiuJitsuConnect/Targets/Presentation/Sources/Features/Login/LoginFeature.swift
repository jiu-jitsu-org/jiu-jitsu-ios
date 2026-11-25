import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct LoginFeature: Sendable {
    
    private enum CancelID { case toast }
    
    // MARK: - State & Action
    @ObservableState
    public struct State: Equatable {
        /// 서버 로그인 진행 중. 이 동안 들어온 다른 로그인·'둘러보기'는 무시한다(진행 중인 로그인이 토큰을 저장하므로).
        /// SNS 화면이 떠 있는 단계는 포함하지 않는다 — 카카오톡에서 로그인 없이 돌아오면 SDK가 응답하지 않아 풀리지 않는다.
        /// 서버 로그인 중인 SNS. 누른 버튼에만 스피너를 띄우는 데 쓴다.
        public var loadingProvider: SNSProvider?
        public var isLoading: Bool { loadingProvider != nil }
        public var toast: ToastState?
        /// 이 기기에서 마지막으로 로그인한 수단 — 그 버튼에 "최근 로그인"을 단다(#380).
        /// 같은 사람도 소셜마다 다른 계정이라, 로그아웃 뒤 다른 버튼을 누르면 새 계정이 생긴다.
        var lastLoginProvider: SNSProvider?
        
        var tempToken: String?
        
        @Presents var sheet: Sheet.State?
        var path = StackState<Path.State>()

        /// 서버 로그인 중이거나 가입 화면(약관 시트 · 닉네임 · 가입 완료)이 떠 있는지. 이 동안 들어온 공유 링크 · 푸시는
        /// 흐름을 끊지 않고 보관한다(#375). 화면으로만 본다 — 임시 토큰은 약관 시트를 쓸어 닫아도 남아 기준이 되지 못한다.
        /// SNS 앱으로 넘어간 단계는 알 수 없어 포함하지 않는다.
        var isSigningUp: Bool {
            isLoading || sheet != nil || !path.isEmpty
        }
        
        public init() {}
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        case sheet(PresentationAction<Sheet.Action>)
        case path(StackAction<Path.State, Path.Action>)
        
        public enum ViewAction: Sendable {
            case onAppear
            case kakaoButtonTapped
            case googleButtonTapped
            case appleButtonTapped
            case aroundButtonTapped
            case toastButtonTapped(ToastState.Action)
            #if BETA
            // Beta 스킴 전용: SNS SDK 없이 테스트 계정(kakao / kakaoTest)으로 즉시 서버 로그인.
            case testLoginTapped
            #endif
        }
        
        public enum InternalAction: Sendable {
            case socialLoginResponse(TaskResult<SNSUser>)
            case serverLoginResponse(TaskResult<AuthInfo>)
            case showToast(ToastState)
            case toastDismissed
        }
        
        public enum DelegateAction: Sendable {
            case didLogin(AuthInfo)
            /// 신규 가입 완료 후 '홈으로'. 진입 경로와 상관없이 홈 탭으로 보내기 위해 로그인과 구분한다(#72).
            case didSignup(AuthInfo)
            case skipLogin
            /// 닉네임 단계에서 가입을 그만둠(#368). 로그인 화면은 이미 첫 화면으로 돌아와 있다.
            case signupAbandoned
        }
    }
    
    @Reducer
    public enum Path: Sendable {
        case nicknameSetting(NicknameSettingFeature)
        case signupComplete(SignupCompleteFeature)
    }
    
    @Reducer
    public enum Sheet: Sendable {
        case termsAgreement(TermsAgreementFeature)
    }
    
    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.recentErrorClient) var recentErrorClient
    @Dependency(\.date) var date
    @Dependency(\.analyticsClient) var analyticsClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.lastLoginProvider = authClient.lastLoginProvider()
                return .none

                // MARK: - 로그인 버튼 탭
            case .view(.googleButtonTapped):
                guard !state.isLoading else { return .none }
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithGoogle() }
                    )))
                }
                
            case .view(.appleButtonTapped):
                guard !state.isLoading else { return .none }
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithApple() }
                    )))
                }
                
            case .view(.kakaoButtonTapped):
                guard !state.isLoading else { return .none }
                return .run { send in
                    await send(.internal(.socialLoginResponse(
                        await TaskResult { try await authClient.loginWithKakao() }
                    )))
                }

            #if BETA
            // MARK: - Beta 전용 테스트 로그인
            // SNS SDK를 우회하고 서버 sns-login에 kakao/kakaoTest로 바로 로그인한다.
            // 이후 흐름(신규→약관/닉네임, 기존→didLogin)은 기존 serverLogin 경로를 그대로 탄다.
            case .view(.testLoginTapped):
                guard !state.isLoading else { return .none }
                return .send(.internal(.socialLoginResponse(.success(
                    SNSUser(accessToken: "kakaoTest", snsProvider: .kakao)
                ))))
            #endif

                // MARK: - 로그인 결과 처리
            case let .internal(.socialLoginResponse(.success(user))):
                state.loadingProvider = user.snsProvider
                return .run { send in
                    await send(.internal(.serverLoginResponse(
                        await TaskResult { try await authClient.serverLogin(user) }
                    )))
                }
                
            case let .internal(.socialLoginResponse(.failure(error))):
                return handleError(state: &state, error: error)
                
            case let .internal(.serverLoginResponse(.success(authInfo))):
                let tappedProvider = state.loadingProvider
                state.loadingProvider = nil
                Log.trace("서버 로그인 성공: isNewUser=\(authInfo.isNewUser ?? false)", category: .network, level: .info)
                // 1. 신규 유저일 경우
                if authInfo.isNewUser == true {
                    guard let tempToken = authInfo.tempToken else {
                        Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                        return .send(.internal(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", status: .error))))
                    }
                    state.tempToken = tempToken
                    // 예전에 다른 수단으로 가입했을 수 있어 약관 시트에서 알린다(#380). 최근 수단이 지금 누른 것과
                    // 다르면 그 수단을 짚어 준다 — 같으면(탈퇴 · 계정 삭제 등) 짚을 수단이 없어 일반 안내만.
                    let otherProvider = state.lastLoginProvider.flatMap { $0 == tappedProvider ? nil : $0 }
                    state.sheet = .termsAgreement(.init(recentOtherProvider: otherProvider))
                } else {
                    // 2. 기존 유저일 경우
                    Log.trace("기존 유저 로그인 성공", category: .debug, level: .info)
                    return .send(.delegate(.didLogin(authInfo)))
                }
                return .none
                
            case let .internal(.serverLoginResponse(.failure(error))):
                return handleError(state: &state, error: error)
                
                // 약관 동의 완료
            case let .sheet(.presented(.termsAgreement(.delegate(.didFinishAgreement(isMarketingAgreed))))):
                guard let tempToken = state.tempToken else {
                    Log.trace("Temp Token is missing for new user.", category: .debug, level: .error)
                    state.sheet = nil
                    return .send(.internal(.showToast(.init(message: "오류가 발생했습니다. 다시 시도해주세요.", status: .error))))
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
                    return .send(.delegate(.didSignup(info)))
                    
                    // 닉네임 설정 실패
                case let .element(id: _, action: .nicknameSetting(.delegate(.signupFailed(message)))):
                    return .send(.internal(.showToast(.init(message: message, status: .error, bottomPadding: 72))))

                    // 임시 토큰 만료 — 이 토큰으로는 가입할 수 없어 첫 화면으로 돌려 로그인부터 다시 하게 한다.
                case .element(id: _, action: .nicknameSetting(.delegate(.signupSessionExpired))):
                    state.tempToken = nil
                    state.path.removeAll()
                    return .send(.internal(.showToast(.init(message: "시간이 지나 가입이 중단됐어요. 다시 로그인해주세요.", status: .info))))

                    // 가입을 그만둠(#368) — 임시 토큰을 버리고 로그인 첫 화면으로. 그다음은 부모가 정한다
                    // (앱 첫 화면은 로그인 화면에 머물고, 앱 안 로그인 창은 둘러보기처럼 닫힌다).
                case .element(id: _, action: .nicknameSetting(.delegate(.signupAbandoned))):
                    state.tempToken = nil
                    state.path.removeAll()
                    return .send(.delegate(.signupAbandoned))

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
                .cancellable(id: CancelID.toast, cancelInFlight: true)
                
            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))
                
            // MARK: - 기타 액션
            case .view(.aroundButtonTapped):
                guard !state.isLoading else { return .none }
                return .send(.delegate(.skipLogin))
                
            case .delegate, .view, .internal:
                return .none
            }
        }
        .ifLet(\.$sheet, action: \.sheet)
        .forEach(\.path, action: \.path)
    }
    
    private func handleError(state: inout State, error: Error) -> Effect<Action> {
        state.loadingProvider = nil
        analyticsClient.logErrorShown(error)

        guard let domainError = error as? DomainError else {
            Log.trace("Unknown login error: \(error)", category: .network, level: .error)
            return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, status: .error))))
        }

        // 실패 이유(탈퇴 처리 · 영구 삭제)를 알리고 오류 코드는 문의 메일용으로 남긴다(#379). 취소는 안내하지 않는다.
        guard let notice = DomainErrorMapper.authFailure(from: domainError) else { return .none }
        if let code = notice.code {
            recentErrorClient.record(RecentError(code: code, occurredAt: date.now))
        }
        return .send(.internal(.showToast(.init(message: notice.message, status: .error))))
    }
}

extension LoginFeature.Path.State: Sendable, Equatable {}
extension LoginFeature.Path.Action: Sendable {}
extension LoginFeature.Sheet.State: Sendable, Equatable {}
extension LoginFeature.Sheet.Action: Sendable {}
