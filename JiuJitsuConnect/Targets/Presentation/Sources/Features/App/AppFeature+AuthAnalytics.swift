//
//  AppFeature+AuthAnalytics.swift
//  Presentation
//
//  시작 · 가입 · 로그인 · 권한 기록(#426). 화면 흐름은 그대로 두고 루트에서 지나가는 액션과 바뀐 상태를 본다.
//  로그인 화면은 앱 첫 화면과 탭 안 모달 두 곳이라 같은 규칙으로 읽는다.
//

import ComposableArchitecture
import Domain
import Foundation

extension AppFeature.Analytics {
    func reduceAuthEvent(into state: inout State, action: Action) {
        if let login = Self.loginAction(of: action) {
            reduceLogin(login.action, isCover: login.isCover, state: &state)
        }
        reducePromptEvent(into: &state, action: action)
        reducePushEvent(into: &state, action: action)
        reduceUpdateEvent(into: &state, action: action)
        logShownLoginPrompts(&state)
    }

    // MARK: - 로그인 · 가입

    private func reduceLogin(_ action: LoginFeature.Action, isCover: Bool, state: inout State) {
        // 첫 화면은 launch, 모달은 띄운 곳 · 이유. 성공하면 모달이 바로 닫히지만 비우는 건 이 다음(updateVisibleScreen)이다.
        let from: AnalyticsEvent.LoginEntry? = isCover ? state.analytics.loginCoverFrom : .launch
        let reason = isCover ? state.analytics.loginCoverReason : nil
        let login = Self.loginState(in: state, isCover: isCover)

        switch action {
        case .view(.kakaoButtonTapped):
            startLogin(.kakao, login: login, from: from, reason: reason, state: &state)
        case .view(.googleButtonTapped):
            startLogin(.google, login: login, from: from, reason: reason, state: &state)
        case .view(.appleButtonTapped):
            startLogin(.apple, login: login, from: from, reason: reason, state: &state)
        #if BETA
        case .view(.testLoginTapped):
            startLogin(.kakao, login: login, from: from, reason: reason, state: &state)
        #endif

        case let .internal(.socialLoginResponse(.failure(error))):
            log(.loginFail(method: state.analytics.loginMethod, reason: Self.loginFailReason(error, isServerStage: false)))

        case let .internal(.serverLoginResponse(.failure(error))):
            log(.loginFail(method: state.analytics.loginMethod, reason: Self.loginFailReason(error, isServerStage: true)))

        case let .delegate(.didLogin(authInfo)):
            let restored = authInfo.userInfo?.deactivatedWithinGrace == true
            log(.login(method: state.analytics.loginMethod, from: from, restored: restored))

        // 가입은 닉네임 단계의 서버 가입 성공 응답에서 센다(완료 화면의 '홈으로'가 아님).
        case let .path(.element(id: id, action: .nicknameSetting(.delegate(.signupSuccessful)))):
            var marketing: Bool?
            if case let .nicknameSetting(nickname)? = login?.path[id: id] {
                marketing = nickname.isMarketingAgreed
            }
            log(.signUp(method: state.analytics.loginMethod, marketing: marketing, from: from))

        // 모달의 같은 버튼은 닫기라 첫 화면만 센다.
        case .delegate(.skipLogin) where !isCover:
            log(.guestStart())

        default:
            break
        }
    }

    /// 서버 로그인 중 누른 버튼은 로그인 화면이 무시하므로 세지 않는다.
    private func startLogin(
        _ method: AnalyticsEvent.LoginMethod,
        login: LoginFeature.State?,
        from: AnalyticsEvent.LoginEntry?,
        reason: AnalyticsEvent.LoginReason?,
        state: inout State
    ) {
        guard login?.isLoading == false else { return }
        state.analytics.loginMethod = method
        log(.loginStart(method: method, from: from, reason: reason))
    }

    private static func loginAction(of action: Action) -> (action: LoginFeature.Action, isCover: Bool)? {
        switch action {
        case let .destination(.presented(.login(loginAction))):
            (loginAction, false)
        case let .destination(.presented(.appTab(.loginCover(.presented(loginAction))))):
            (loginAction, true)
        default:
            nil
        }
    }

    private static func loginState(in state: State, isCover: Bool) -> LoginFeature.State? {
        switch state.destination {
        case let .login(login)? where !isCover:
            login
        case let .appTab(appTab)? where isCover:
            appTab.loginCover
        default:
            nil
        }
    }

    private static func loginFailReason(_ error: any Error, isServerStage: Bool) -> AnalyticsEvent.LoginFailReason {
        let fallback: AnalyticsEvent.LoginFailReason = isServerStage ? .serverError : .snsError
        guard let domainError = error as? DomainError else { return fallback }
        switch domainError {
        case .signInCancelled:
            return .cancel
        case .accountProblem, .apiError(.alreadyWithdrawn, _), .apiError(.withdrawnAccountExpired, _):
            return .accountProblem
        case .permissionRequired:
            return .permissionRequired
        case .missingProfileData:
            return .missingProfile
        default:
            return fallback
        }
    }

    // MARK: - 로그인 안내 · 로그아웃 · 탈퇴

    private func reducePromptEvent(into state: inout State, action: Action) {
        switch action {
        // 웹 · 게스트 내 이름이 띄운 로그인 안내 알럿의 이유. 알럿은 다음 액션에서 뜬다.
        case let .destination(.presented(.appTab(.home(.delegate(.loginPromptRequested(reason)))))),
             let .destination(.presented(.appTab(.competition(.delegate(.webSubview(.loginPromptRequested(reason))))))),
             let .destination(.presented(.appTab(.myPage(.delegate(.webSubview(.loginPromptRequested(reason))))))):
            state.analytics.loginPromptReason = AppTabFeature.loginReason(from: reason)

        case .destination(.presented(.appTab(.home(.delegate(.myProfileRequested))))):
            guard case let .appTab(appTab)? = state.destination, appTab.authInfo.isGuest else { return }
            state.analytics.loginPromptReason = .profile

        case .destination(.presented(.appTab(.view(.loginPromptCancelTapped)))),
             .destination(.presented(.appTab(.view(.loginPromptDismissed)))):
            state.analytics.loginPromptReason = nil

        case .destination(.presented(.appTab(.internal(.webLogoutCompleted)))):
            log(.logout())

        case .destination(.presented(.appTab(.myPage(.delegate(.settings(.didWithdrawSuccessfully)))))):
            log(.accountDelete())

        default:
            break
        }
    }

    /// 로그인 안내 · 만료 안내가 새로 뜬 순간을 센다. `from`은 안내가 뜬 화면(웹뷰면 웹이 알린 화면 이름).
    private func logShownLoginPrompts(_ state: inout State) {
        let appTab: AppTabFeature.State? = if case let .appTab(appTab)? = state.destination { appTab } else { nil }
        let from = Self.screenName(of: state.analytics.visibleScreen)

        let isPromptShown = appTab?.isLoginPromptPresented == true
        if isPromptShown, !state.analytics.isLoginPromptShown {
            log(.loginPromptView(reason: state.analytics.loginPromptReason, from: from))
        }
        state.analytics.isLoginPromptShown = isPromptShown

        let isExpiryShown = appTab?.isSessionExpiredAlertPresented == true
        if isExpiryShown, !state.analytics.isSessionExpiredPromptShown {
            log(.loginPromptView(reason: .sessionExpired, from: from))
        }
        state.analytics.isSessionExpiredPromptShown = isExpiryShown
    }

    /// 게스트 MY의 로그인 안내(사전 `my_tab`). MY 화면 기록이 새로 남을 때 함께 센다 — 다시 보임 · 앱 복귀는 뺀다.
    func logMyTabLoginPrompt(screen: AppFeature.VisibleScreen, from: String?, state: State) {
        guard
            screen.id == "my",
            from != "back", from != "resume",
            case let .appTab(appTab)? = state.destination, appTab.authInfo.isGuest
        else { return }
        log(.loginPromptView(reason: .myTab, from: Self.screenName(of: screen)))
    }

    private static func screenName(of screen: AppFeature.VisibleScreen?) -> String? {
        guard case let .string(name)? = screen?.event?.parameters["screen_name"] else { return nil }
        return name
    }

    // MARK: - 알림 권한

    private func reducePushEvent(into state: inout State, action: Action) {
        switch action {
        case let .destination(.presented(.appTab(.internal(.notificationPromptPermissionAnswered(granted))))):
            logPermissionAnswer(granted: granted, trigger: .contentCreate, state: &state)

        case let .destination(.presented(.appTab(.internal(.competitionSettingPermissionAnswered(granted))))):
            logPermissionAnswer(granted: granted, trigger: .settingsCompetition, state: &state)

        case let .destination(.presented(.appTab(.myPage(.path(.element(
            id: _,
            action: .settings(.destination(.presented(.notificationSetting(.internal(.devicePermissionAnswered(granted))))))
        )))))):
            logPermissionAnswer(granted: granted, trigger: .settingsDevice, state: &state)

        // 웹의 관심 대회 '알림 받기'(#395). 권한 창은 웹 화면 Feature가 띄우고 결과만 올라온다.
        case let .destination(.presented(.appTab(.home(.delegate(.competitionAlertsChecked(check)))))),
             let .destination(.presented(.appTab(.competition(.delegate(.competitionAlertsChecked(check)))))),
             let .destination(.presented(.appTab(.myPage(.delegate(.webSubview(.competitionAlertsChecked(check))))))):
            if check == .grantedNow || check == .deniedNow {
                logPermissionAnswer(granted: check == .grantedNow, trigger: .competitionAlert, state: &state)
            }
            // 꺼짐 안내는 로그인 동안 한 번만 뜬다 — 이번에 실제로 떴을 때만 기억한다.
            if case let .appTab(appTab)? = state.destination, appTab.isDeviceNotificationAlertPresented,
               state.analytics.deviceAlertTrigger == nil {
                state.analytics.deviceAlertTrigger = .competitionAlert
            }

        // 설정 › 알림의 관심 대회 알림 켜기만 이 액션으로 안내를 띄운다.
        case .destination(.presented(.appTab(.internal(.showDeviceNotificationAlert)))):
            state.analytics.deviceAlertTrigger = .settingsCompetition

        case .destination(.presented(.appTab(.view(.deviceNotificationAlertSettingsTapped)))):
            answerDeviceAlert(.openSettings, state: &state)

        case .destination(.presented(.appTab(.view(.deviceNotificationAlertDismissed)))):
            answerDeviceAlert(.later, state: &state)

        default:
            break
        }
        // 버튼 없이 닫힌 안내(로그아웃 · 세션 만료 · 탈퇴로 게스트가 됨)의 곳을 다음 안내로 넘기지 않는다.
        if case let .appTab(appTab)? = state.destination, appTab.isDeviceNotificationAlertPresented { return }
        state.analytics.deviceAlertTrigger = nil
    }

    private func logPermissionAnswer(granted: Bool, trigger: AnalyticsEvent.PushTrigger, state: inout State) {
        guard !state.analytics.didLogPermissionAnswer else { return }
        state.analytics.didLogPermissionAnswer = true
        log(.pushPermissionResult(granted: granted, trigger: trigger))
    }

    private func answerDeviceAlert(_ action: AnalyticsEvent.PushSettingsAction, state: inout State) {
        guard let trigger = state.analytics.deviceAlertTrigger else { return }
        state.analytics.deviceAlertTrigger = nil
        log(.pushSettingsPrompt(action, trigger: trigger))
    }

    // MARK: - 업데이트 안내

    private func reduceUpdateEvent(into state: inout State, action: Action) {
        switch action {
        case .destination(.presented(.splash(.delegate(.updateRequired)))):
            showRequiredUpdate(from: "launch", state: &state)

        case .internal(.updateRequiredOnResume):
            showRequiredUpdate(from: "resume", state: &state)

        case .view(.requiredUpdateTapped):
            log(.appUpdatePrompt(.force, action: .update, from: state.analytics.requiredUpdateFrom ?? "launch"))

        case .destination(.presented(.splash(.view(.recommendedUpdateTapped)))):
            answerRecommendedUpdate(.update, state: &state)

        case .destination(.presented(.splash(.view(.recommendedUpdateLaterTapped)))):
            answerRecommendedUpdate(.later, state: &state)

        default:
            break
        }
        // 권장 업데이트 안내는 스플래시가 버전 확인 · 최소 노출을 마친 뒤 상태로만 띄운다.
        if case let .splash(splash)? = state.destination, splash.recommendedUpdateVersion != nil,
           !state.analytics.isRecommendedUpdateShown {
            state.analytics.isRecommendedUpdateShown = true
            log(.appUpdatePrompt(.optional, action: .view, from: "launch"))
        }
    }

    private func showRequiredUpdate(from: String, state: inout State) {
        state.analytics.requiredUpdateFrom = from
        log(.appUpdatePrompt(.force, action: .view, from: from))
    }

    private func answerRecommendedUpdate(_ action: AnalyticsEvent.UpdatePromptAction, state: inout State) {
        guard state.analytics.isRecommendedUpdateShown else { return }
        state.analytics.isRecommendedUpdateShown = false
        log(.appUpdatePrompt(.optional, action: action, from: "launch"))
    }
}
