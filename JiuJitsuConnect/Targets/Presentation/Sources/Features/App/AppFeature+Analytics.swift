//
//  AppFeature+Analytics.swift
//  Presentation
//
//  앱 전체의 분석 기록(#423). 기능 코드는 기록을 모르게 두고, 루트에서 지나가는 액션을 보고 이벤트 · 사용자 속성으로 바꾼다.
//  이벤트를 더할 때는 여기 `reduce`에 액션 → 이벤트 한 줄을 더한다.
//

import ComposableArchitecture
import Domain
import Foundation

extension AppFeature {
    /// 복귀 기록에 필요한 앱 생명주기 기억.
    public struct AnalyticsState: Equatable, Sendable {
        /// 앱을 켠 첫 `app_open`을 남겼다. 루트 화면이 바뀌면 onAppear가 다시 와서 한 번만 센다.
        var hasLoggedColdOpen = false
        /// 백그라운드에 다녀왔다. 권한 창 · 제어 센터를 닫을 때는 `.inactive`에서 돌아오므로 이것이 없어 세지 않는다.
        var isInBackground = false
        /// 입구(푸시 · 링크)를 기다리는 `app_open`. 콜드 스타트의 푸시 탭 · 링크는 화면이 뜬 뒤에 온다.
        var pendingOpen: AnalyticsEvent.AppState?
        /// 돌아오기 전에 먼저 온 입구(푸시 탭이 `.active`보다 먼저 올 때).
        var pendingSource: AnalyticsEvent.OpenSource?
        /// 마지막으로 보낸 계정 속성(MY 프로필 기준). 같은 값은 다시 보내지 않는다.
        var sentProfileProperties: [AnalyticsUserProperty: String?] = [:]
        /// 지금 맨 위에 보이는 화면(#425).
        var visibleScreen: VisibleScreen?
        /// 마지막으로 screen_view를 남긴 화면. 맨 위 화면이 잠깐 그대로 있은 뒤 이것과 다를 때만 남긴다.
        var loggedScreen: VisibleScreen?
        /// 앱으로 돌아왔을 때 맨 위였던 화면. 그 화면이 그대로면 from=resume으로 다시 남긴다(새 세션의 첫 화면이 비지 않게).
        /// 푸시 · 링크로 돌아와 다른 화면이 뜨면 그 화면은 웹 · 앱이 정한 입구로 남는다.
        var resumingScreenID: String?
        /// 백그라운드로 나갈 때 맨 위였던 화면. 백그라운드 중 푸시 · 링크가 화면을 바꿨으면 그 화면은 resume이 아니다.
        var backgroundScreenID: String?
        /// 로그인 모달을 띄운 곳(login_prompt · web_modal). 모달이 닫히면 비운다.
        var loginCoverFrom: String?
        /// 마지막으로 보낸 회원 ID. 같은 값은 다시 보내지 않는다. 바깥 nil은 아직 안 보냄 — GA는 이전 실행의 값을 기억한다.
        var sentUserID: String??
    }

    /// 루트 분석 리듀서. 상태는 `AnalyticsState`만 바꾸고 화면 흐름에는 끼어들지 않는다.
    struct Analytics: Reducer {
        typealias State = AppFeature.State
        typealias Action = AppFeature.Action

        private enum CancelID: Hashable, Sendable {
            case openSourceWait
            case screenViewSettle
        }

        /// 입구를 기다리는 시간. 넘으면 아이콘으로 연 것으로 센다.
        static let openSourceWaitDuration: Duration = .seconds(1)
        /// 맨 위 화면이 이만큼 그대로 있어야 본 것으로 센다. 링크 · 푸시는 탭을 바꾼 뒤 다음 액션에서 상세를 쌓아,
        /// 그 사이 잠깐 맨 위였던 탭 첫 화면을 세지 않게 한다.
        static let screenViewSettleDuration: Duration = .milliseconds(500)

        @Dependency(\.analyticsClient) var analyticsClient
        @Dependency(\.authClient) var authClient
        @Dependency(\.notificationPermissionClient) var notificationPermissionClient
        @Dependency(\.continuousClock) var clock

        func reduce(into state: inout State, action: Action) -> Effect<Action> {
            let screenEffect = reduceScreenEvent(into: &state, action: action)
            let effect = reduceEvent(into: &state, action: action)
            if case .destination(.presented(.appTab)) = action {
                syncProfileProperties(&state)
            }
            return .merge(effect, screenEffect, updateVisibleScreen(&state))
        }

        private func reduceEvent(into state: inout State, action: Action) -> Effect<Action> {
            switch action {
            // MARK: app_open · push_enabled

            case .view(.onAppear):
                guard !state.analytics.hasLoggedColdOpen else { return .none }
                state.analytics.hasLoggedColdOpen = true
                return .merge(beginAppOpen(.cold, state: &state), updatePushEnabled())

            case .view(.sceneEnteredBackground):
                state.analytics.isInBackground = true
                // 입구를 기다리던 중에 나가면 지금까지 본 대로 남긴다.
                return flushPendingOpen(&state)

            case .view(.sceneBecameActive):
                // 권한 창에서 돌아와도 권한이 바뀌었을 수 있어 매번 본다.
                let pushEnabled = updatePushEnabled()
                guard state.analytics.isInBackground else { return pushEnabled }
                state.analytics.isInBackground = false
                if let source = state.analytics.pendingSource {
                    state.analytics.pendingSource = nil
                    log(.appOpen(from: source, appState: .warm))
                    return pushEnabled
                }
                return .merge(beginAppOpen(.warm, state: &state), pushEnabled)

            case .internal(.pushNotificationTapped):
                return openSourceArrived(.push, state: &state)

            case let .view(.deepLinkReceived(url)):
                // 로그인 SDK 콜백(카카오 · 구글 스킴)은 입구가 아니다.
                guard DeepLinkParser.parse(url) != nil else { return .none }
                return openSourceArrived(Self.openSource(of: url), state: &state)

            case .internal(.appOpenSourceWaitElapsed):
                return flushPendingOpen(&state)

            case .internal(.screenViewSettled):
                logSettledScreen(&state)
                return .none

            // MARK: session_restore

            case let .destination(.presented(.splash(.internal(.autoLoginFinished(authInfo, isSessionExpired))))):
                if let authInfo {
                    log(.sessionRestore(.restored))
                    updateLoginMethod()
                    updateMember(authInfo.userInfo, state: &state)
                } else {
                    log(.sessionRestore(isSessionExpired ? .fail : .guest))
                    // GA는 회원 ID · 속성을 실행 사이에 기억한다. 지난 실행이 로그인 채로 끝났으면 여기서 지운다.
                    clearMemberProperties(&state)
                }
                return .none

            case let .destination(.presented(.splash(.internal(.autoLoginConnectionFailed(isTimedOut))))):
                log(.sessionRestore(isTimedOut ? .timeout : .fail))
                return .none

            // MARK: 사용자 속성 — 이미 받는 응답에서

            case let .destination(.presented(.login(.delegate(.didLogin(authInfo))))),
                 let .destination(.presented(.login(.delegate(.didSignup(authInfo))))),
                 let .destination(.presented(.appTab(.loginCover(.presented(.delegate(.didLogin(authInfo))))))),
                 let .destination(.presented(.appTab(.loginCover(.presented(.delegate(.didSignup(authInfo))))))):
                updateLoginMethod()
                updateMember(authInfo.userInfo, state: &state)
                return .none

            case .destination(.presented(.appTab(.internal(.webLogoutCompleted)))),
                 .destination(.presented(.appTab(.internal(.handleSessionExpired)))):
                // 다음에 이 기기로 들어오는 사람에게 이전 계정 값이 붙지 않게 지운다.
                clearMemberProperties(&state)
                return .none

            case .destination(.presented(.appTab(.myPage(.delegate(.settings(.didWithdrawSuccessfully)))))):
                clearMemberProperties(&state)
                analyticsClient.resetAnalyticsData()
                return .none

            default:
                return .none
            }
        }

        // MARK: - screen_view

        /// 화면 기록에 필요한 앱 생명주기 · 로그인 입구. 복귀 판정(isInBackground)을 reduceEvent가 바꾸기 전에 본다.
        private func reduceScreenEvent(into state: inout State, action: Action) -> Effect<Action> {
            switch action {
            case .view(.sceneEnteredBackground):
                state.analytics.backgroundScreenID = state.analytics.visibleScreen?.id
                // 나가기 직전 연 화면은 보지 않은 것이라 기다리던 기록을 버린다.
                return .cancel(id: CancelID.screenViewSettle)

            case .view(.sceneBecameActive):
                guard state.analytics.isInBackground else { return .none }
                let currentID = state.analytics.visibleScreen?.id
                state.analytics.resumingScreenID = currentID == state.analytics.backgroundScreenID ? currentID : nil
                state.analytics.backgroundScreenID = nil
                return scheduleScreenViewSettle()

            case .destination(.presented(.appTab(.view(.loginPromptLoginTapped)))):
                state.analytics.loginCoverFrom = "login_prompt"
                return .none

            case .destination(.presented(.appTab(.home(.delegate(.loginModalRequested))))),
                 .destination(.presented(.appTab(.myPage(.delegate(.webSubview(.loginModalRequested)))))),
                 .destination(.presented(.appTab(.competition(.delegate(.webSubview(.loginModalRequested)))))):
                state.analytics.loginCoverFrom = "web_modal"
                return .none

            default:
                return .none
            }
        }

        /// 액션이 지나갈 때마다 맨 위 화면을 다시 계산한다. 바뀌었으면(다른 화면 · 다시 보임 · 웹뷰 안 화면 이동)
        /// 잠깐 기다렸다가, 그때도 맨 위인 화면을 남긴다.
        private func updateVisibleScreen(_ state: inout State) -> Effect<Action> {
            // 로그인 모달은 입구 액션 다음 액션에서 뜬다 — 입구는 모달이 떠 있다 닫힐 때 비운다.
            if state.analytics.visibleScreen?.id.hasPrefix(ScreenView.loginCoverID) == true,
               case let .appTab(appTab)? = state.destination, appTab.loginCover == nil {
                state.analytics.loginCoverFrom = nil
            }
            let screen = ScreenView.visibleScreen(in: state)
            guard screen != state.analytics.visibleScreen else { return .none }
            state.analytics.visibleScreen = screen
            // 백그라운드에서 바뀐 화면(늦게 온 웹 화면 알림 등)은 보지 않은 것 — 돌아올 때 resume으로 남긴다.
            guard !state.analytics.isInBackground else { return .none }
            return scheduleScreenViewSettle()
        }

        private func scheduleScreenViewSettle() -> Effect<Action> {
            .run { send in
                try await clock.sleep(for: Self.screenViewSettleDuration)
                await send(.internal(.screenViewSettled))
            }
            .cancellable(id: CancelID.screenViewSettle, cancelInFlight: true)
        }

        private func logSettledScreen(_ state: inout State) {
            let screen = state.analytics.visibleScreen
            let isResuming = screen != nil && screen?.id == state.analytics.resumingScreenID
            state.analytics.resumingScreenID = nil
            guard isResuming || screen != state.analytics.loggedScreen else { return }
            state.analytics.loggedScreen = screen
            if let event = screen?.event {
                log(isResuming ? event.replacingFrom("resume") : event)
            }
        }

        // MARK: - app_open

        /// 입구가 곧 올 수 있어 잠깐 기다렸다 남긴다. 그 사이 입구가 오면 바로 남긴다.
        private func beginAppOpen(_ appState: AnalyticsEvent.AppState, state: inout State) -> Effect<Action> {
            state.analytics.pendingOpen = appState
            return .run { send in
                try await clock.sleep(for: Self.openSourceWaitDuration)
                await send(.internal(.appOpenSourceWaitElapsed))
            }
            .cancellable(id: CancelID.openSourceWait, cancelInFlight: true)
        }

        private func openSourceArrived(_ source: AnalyticsEvent.OpenSource, state: inout State) -> Effect<Action> {
            if let appState = state.analytics.pendingOpen {
                state.analytics.pendingOpen = nil
                log(.appOpen(from: source, appState: appState))
                return .cancel(id: CancelID.openSourceWait)
            }
            // 백그라운드에서 먼저 온 입구는 돌아올 때 쓴다. 앱을 쓰는 중 누른 링크 · 알림은 앱을 연 것이 아니다.
            if state.analytics.isInBackground {
                state.analytics.pendingSource = source
            }
            return .none
        }

        private func flushPendingOpen(_ state: inout State) -> Effect<Action> {
            guard let appState = state.analytics.pendingOpen else { return .none }
            state.analytics.pendingOpen = nil
            log(.appOpen(from: .icon, appState: appState))
            return .cancel(id: CancelID.openSourceWait)
        }

        /// 공유 링크(`utm_medium=share`)가 먼저, 그다음 전송 수단(앱 주소 · 유니버설 링크)으로 가른다.
        /// 앱 주소는 안에 실린 https 링크의 꼬리표를 본다.
        static func openSource(of url: URL) -> AnalyticsEvent.OpenSource {
            let isScheme = url.scheme?.lowercased() != "https"
            let inner = isScheme
                ? URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "url" })?.value.flatMap(URL.init(string:))
                : url
            let medium = inner
                .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?.first(where: { $0.name == "utm_medium" })?.value
            if medium == "share" { return .shareLink }
            return isScheme ? .scheme : .deeplink
        }

        // MARK: - 사용자 속성

        private func updatePushEnabled() -> Effect<Action> {
            .run { [analyticsClient, notificationPermissionClient] _ in
                let isGranted = await notificationPermissionClient.status() == .granted
                analyticsClient.setUserProperty(Self.flag(isGranted), .pushEnabled)
            }
        }

        /// 로그인 · 복원 직후 저장된 SNS 종류로 남긴다.
        private func updateLoginMethod() {
            guard let provider = authClient.storedProvider() else { return }
            analyticsClient.setUserProperty(provider.rawValue.lowercased(), .loginMethod)
        }

        /// MY가 화면에 반영한 프로필(조회 · 재조회 · 저장 결과 모두)을 기준으로 바뀐 속성만 보낸다.
        /// 응답이 아니라 상태를 보므로 화면이 버린 늦은 재조회 응답은 쓰지 않는다.
        private func syncProfileProperties(_ state: inout State) {
            guard case let .appTab(appTab)? = state.destination, !appTab.authInfo.isGuest else { return }
            var properties: [AnalyticsUserProperty: String?] = [:]
            if let profile = appTab.myPage.communityProfile {
                properties[.belt] = profile.beltRank?.rawValue.lowercased() ?? "none"
                // 띠가 없으면 nil 값으로 남겨 속성을 지운다(첨자 대입에 nil을 넣으면 키가 사라진다).
                let stripes: String? = profile.beltRank == nil ? nil : profile.beltStripe.map { String($0.count) }
                properties.updateValue(stripes, forKey: .stripes)
                properties[.hasCompRecord] = Self.flag(!profile.competitions.isEmpty)
                properties[.hasGym] = Self.flag(!(profile.academyName ?? "").isEmpty)
            }
            if let userProfile = appTab.myPage.userProfile {
                properties[.coachRole] = Self.flag(userProfile.userRole == .owner)
                // 로그인 응답 뒤 관리자가 계정 구분을 바꿨을 수 있어 프로필 값으로도 맞춘다. 모르는 값이면 그대로 둔다.
                if let accountType = AnalyticsUserProperty.accountTypeValue(userProfile.accountType) {
                    properties[.accountType] = accountType
                }
                if let analyticsId = Self.nonEmpty(userProfile.analyticsId) {
                    sendUserID(analyticsId, state: &state)
                }
            }
            for (property, value) in properties.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                guard state.analytics.sentProfileProperties[property] != .some(value) else { continue }
                state.analytics.sentProfileProperties[property] = .some(value)
                analyticsClient.setUserProperty(value, property)
            }
        }

        /// 로그인 · 가입 · 복원 응답의 분석용 ID와 계정 구분. 값이 없으면 지워 이전 계정 값이 남지 않게 한다.
        private func updateMember(_ userInfo: AuthInfo.UserInfo?, state: inout State) {
            sendUserID(Self.nonEmpty(userInfo?.analyticsId), state: &state)
            let accountType = AnalyticsUserProperty.accountTypeValue(userInfo?.accountType)
            guard state.analytics.sentProfileProperties[.accountType] != .some(accountType) else { return }
            state.analytics.sentProfileProperties[.accountType] = .some(accountType)
            analyticsClient.setUserProperty(accountType, .accountType)
        }

        private func sendUserID(_ userID: String?, state: inout State) {
            guard state.analytics.sentUserID != .some(userID) else { return }
            state.analytics.sentUserID = .some(userID)
            analyticsClient.setUserID(userID)
        }

        /// 기기 권한(`push_enabled`)은 계정과 무관해 남긴다. 회원 ID는 빈 문자열이 아니라 nil로 지운다.
        private func clearMemberProperties(_ state: inout State) {
            state.analytics.sentUserID = .some(nil)
            analyticsClient.setUserID(nil)
            state.analytics.sentProfileProperties = [:]
            for property in AnalyticsUserProperty.allCases where property != .pushEnabled {
                analyticsClient.setUserProperty(nil, property)
            }
        }

        private func log(_ event: AnalyticsEvent) {
            analyticsClient.logEvent(event)
        }

        private static func nonEmpty(_ value: String?) -> String? {
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        private static func flag(_ value: Bool) -> String {
            value ? "true" : "false"
        }
    }
}
