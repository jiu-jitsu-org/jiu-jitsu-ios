//
//  AnalyticsEvent.swift
//  Presentation
//
//  GA 이벤트 사전(#423). 이름은 사전에 있는 것만 만들 수 있다 — 이후 이슈가 이벤트를 더하고,
//  웹뷰 브리지(#424)는 받은 이름을 `Name(rawValue:)`로 걸러 사전에 없는 이름을 버린다.
//

import Foundation

public struct AnalyticsEvent: Equatable, Sendable {
    public enum Name: String, CaseIterable, Sendable {
        case appOpen = "app_open"
        case sessionRestore = "session_restore"

        // 시작 · 가입 · 로그인 · 권한(#426). login_prompt_view는 웹과 같이 쓴다(아래 웹 목록).
        case guestStart = "guest_start"
        case loginStart = "login_start"
        case login
        case loginFail = "login_fail"
        case signUp = "sign_up"
        case logout
        case accountDelete = "account_delete"
        case pushPermissionResult = "push_permission_result"
        case pushSettingsPrompt = "push_settings_prompt"
        case appUpdatePrompt = "app_update_prompt"

        // 웹뷰가 ANALYTICS_EVENT로 보내는 기록(#424). 이벤트 사전 v2에서 범위에 FE가 있는 것.
        // 사전에 없는 이름은 브리지가 버린다 — 웹에 이벤트를 더하면 여기에도 더한다.
        case screenView = "screen_view"
        case loginPromptView = "login_prompt_view"
        case selectContent = "select_content"
        case listLoadMore = "list_load_more"
        case postWriteStart = "post_write_start"
        case photoAttach = "photo_attach"
        case postWriteCancel = "post_write_cancel"
        case postCreate = "post_create"
        case postEdit = "post_edit"
        case postDelete = "post_delete"
        case commentCreate = "comment_create"
        case commentDelete = "comment_delete"
        case commentSortChange = "comment_sort_change"
        case linkOpen = "link_open"
        case competitionFilterApply = "competition_filter_apply"
        case competitionViewChange = "competition_view_change"
        case bannerView = "banner_view"
        case bannerClick = "banner_click"
        case competitionInterest = "competition_interest"
        case competitionLinkClick = "competition_link_click"
        case competitionStoryMore = "competition_story_more"
        case feedCompetitionFilter = "feed_competition_filter"
        case competitionInfoReport = "competition_info_report"
        case notificationReadAll = "notification_read_all"
        case contentAlertToggle = "content_alert_toggle"
        case share = "share"
        case openAppClick = "open_app_click"
        case contentLike = "content_like"
        case contentSave = "content_save"
        case contentHide = "content_hide"
        case reportSubmit = "report_submit"
        case userBlock = "user_block"
        case balanceVote = "balance_vote"
        case beltUpdate = "belt_update"
        case beltPrompt = "belt_prompt"
        case errorShown = "error_shown"
        case webVital = "web_vital"
        case uiClick = "ui_click"
        case categorySelect = "category_select"
        case search = "search"
        case featureInterest = "feature_interest"
    }

    /// 어디서 기록했나. 클라이언트가 모든 이벤트에 `surface` 꼬리표로 붙인다.
    public enum Surface: String, Sendable {
        case native
        case webview
    }

    public enum Value: Equatable, Sendable {
        case string(String)
        case int(Int)
    }

    public let name: Name
    public let parameters: [String: Value]
    public let surface: Surface

    public init(_ name: Name, parameters: [String: Value] = [:], surface: Surface = .native) {
        self.name = name
        self.parameters = parameters
        self.surface = surface
    }
}

// MARK: - 사전 이벤트

extension AnalyticsEvent {
    /// `app_open`의 `from` — 앱이 열린 입구(사전 "from 값").
    public enum OpenSource: String, Sendable {
        case icon
        case push
        /// 유니버설 링크
        case deeplink
        /// 앱 주소(`bjjossapp://`)
        case scheme
        /// 공유 링크(`utm_medium=share`)
        case shareLink = "share_link"
    }

    /// `app_open`의 `app_state` — 앱이 꺼져 있다 켜졌나(cold), 백그라운드에서 돌아왔나(warm).
    public enum AppState: String, Sendable {
        case cold
        case warm
    }

    /// `session_restore`의 `result` — 스플래시 자동 로그인 결과.
    public enum SessionRestoreResult: String, Sendable {
        /// 저장된 로그인으로 들어감
        case restored = "ok"
        /// 저장된 로그인이 없음
        case guest
        /// 저장된 로그인이 만료됐거나 서버에 닿지 못함
        case fail
        /// 자동 로그인을 기다리다 시간 초과
        case timeout
    }

    public static func appOpen(from source: OpenSource, appState: AppState) -> Self {
        Self(.appOpen, parameters: ["from": .string(source.rawValue), "app_state": .string(appState.rawValue)])
    }

    public static func sessionRestore(_ result: SessionRestoreResult) -> Self {
        Self(.sessionRestore, parameters: ["result": .string(result.rawValue)])
    }

    /// 앱이 그리는 화면(사전 "화면 이름" 중 native). 웹뷰 화면 이름은 웹이 알린 값을 그대로 쓴다(#425).
    public enum NativeScreen: String, Sendable {
        case login
        case signupTerms = "signup_terms"
        case signupNickname = "signup_nickname"
        case signupComplete = "signup_complete"
        case myProfile = "my_profile"
        case myProfileEdit = "my_profile_edit"
        case beltPromotion = "belt_promotion"
        case competitionRecordAdd = "competition_record_add"
        case userProfile = "user_profile"
        case settings
        case notificationSettings = "notification_settings"
        /// 약관 · 처리방침(사전에선 webview). 브리지가 없는 약관 웹뷰라 웹 대신 앱이 주소로 남긴다.
        case policy
    }

    /// `my_profile_edit`의 section(사전 "section" 중 프로필 항목).
    public enum ProfileSection: String, Sendable {
        case academy, nickname, photo, belt, position, technique, submission, competition
        case ownerCert = "owner_cert"
        case headerPattern = "header_pattern"
    }

    /// `section`: 한 화면 안의 부분(MY 편집 항목 등, 사전 "section").
    /// `from`: 들어온 입구(사전 "from 값"). 모르면 싣지 않는다.
    public static func screenView(
        _ screen: NativeScreen,
        section: String? = nil,
        from: String? = nil,
        screenClass: String = "native"
    ) -> Self {
        var parameters: [String: Value] = ["screen_name": .string(screen.rawValue), "screen_class": .string(screenClass)]
        if let section { parameters["section"] = .string(section) }
        if let from { parameters["from"] = .string(from) }
        return Self(.screenView, parameters: parameters)
    }

    /// 같은 기록에서 `from`만 바꾼 것(앱으로 돌아와 지금 화면을 다시 남길 때 `resume`).
    func replacingFrom(_ from: String) -> Self {
        var parameters = parameters
        parameters["from"] = .string(from)
        return Self(name, parameters: parameters, surface: surface)
    }
}

// MARK: - 시작 · 가입 · 로그인 · 권한 (#426)

extension AnalyticsEvent {
    /// 로그인 SNS(사전 `method`).
    public enum LoginMethod: String, Sendable {
        case kakao, google, apple
    }

    /// `login_fail`의 reason(사전 "로그인 실패").
    public enum LoginFailReason: String, Sendable {
        case cancel
        /// 탈퇴 처리 · 영구 삭제 등 계정 문제
        case accountProblem = "account_problem"
        case permissionRequired = "permission_required"
        case missingProfile = "missing_profile"
        /// SNS 단계의 그 밖 실패
        case snsError = "sns_error"
        /// 서버 로그인 단계의 그 밖 실패(네트워크 포함)
        case serverError = "server_error"
    }

    /// 알림 권한을 물은 순간(사전 `trigger`). 앱 진입 · 로그인 직후는 #333부터 묻지 않는다.
    public enum PushTrigger: String, Sendable {
        /// 글 · 댓글을 올린 뒤 안내의 [알림 받기](#333)
        case contentCreate = "content_create"
        /// 웹의 관심 대회 '알림 받기'(#257)
        case competitionAlert = "competition_alert"
        /// 설정 › 알림의 관심 대회 알림 켜기
        case settingsCompetition = "settings_competition"
        /// 설정 › 알림의 기기 알림 켜기
        case settingsDevice = "settings_device"
    }

    /// "기기 알림이 꺼져 있어요" 안내의 답(사전 `action`).
    public enum PushSettingsAction: String, Sendable {
        case openSettings = "open_settings"
        /// [나중에] · 닫힘
        case later
    }

    public enum UpdateType: String, Sendable {
        case force
        case optional
    }

    /// 업데이트 안내가 뜸(`view`)과 답(사전 `action`).
    public enum UpdatePromptAction: String, Sendable {
        case view, update, later
    }

    public static func guestStart() -> Self {
        Self(.guestStart)
    }

    /// `reason`: 로그인 안내 이유(사전 "로그인 안내"). `from` · `reason`은 모르면 싣지 않는다.
    public static func loginPromptView(reason: String?, from: String?) -> Self {
        Self(.loginPromptView, parameters: strings(["reason": reason, "from": from]))
    }

    public static func loginStart(method: LoginMethod, from: String?, reason: String?) -> Self {
        Self(.loginStart, parameters: strings(["method": method.rawValue, "from": from, "reason": reason]))
    }

    /// `restored`: 탈퇴 유예 중 다시 로그인해 탈퇴가 취소됨.
    public static func login(method: LoginMethod?, from: String?, restored: Bool) -> Self {
        Self(.login, parameters: strings(["method": method?.rawValue, "from": from, "restored": flag(restored)]))
    }

    public static func loginFail(method: LoginMethod?, reason: LoginFailReason) -> Self {
        Self(.loginFail, parameters: strings(["method": method?.rawValue, "reason": reason.rawValue]))
    }

    public static func signUp(method: LoginMethod?, marketing: Bool?, from: String?) -> Self {
        Self(.signUp, parameters: strings(["method": method?.rawValue, "marketing": marketing.map(flag), "from": from]))
    }

    public static func logout() -> Self {
        Self(.logout)
    }

    public static func accountDelete() -> Self {
        Self(.accountDelete)
    }

    public static func pushPermissionResult(granted: Bool, trigger: PushTrigger) -> Self {
        Self(.pushPermissionResult, parameters: strings(["result": granted ? "granted" : "denied", "trigger": trigger.rawValue]))
    }

    public static func pushSettingsPrompt(_ action: PushSettingsAction, trigger: PushTrigger) -> Self {
        Self(.pushSettingsPrompt, parameters: strings(["action": action.rawValue, "trigger": trigger.rawValue]))
    }

    /// `from`: 스플래시에서 뜨면 launch, 켜 둔 앱을 다시 열 때 확인해 뜨면 resume.
    public static func appUpdatePrompt(_ type: UpdateType, action: UpdatePromptAction, from: String) -> Self {
        Self(.appUpdatePrompt, parameters: strings(["update_type": type.rawValue, "action": action.rawValue, "from": from]))
    }

    /// nil 값은 꼬리표에서 뺀다.
    private static func strings(_ values: [String: String?]) -> [String: Value] {
        values.compactMapValues { $0.map(Value.string) }
    }

    private static func flag(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}

// MARK: - 사용자 속성

/// GA 사용자 속성(사전 "사용자 속성"). `signup_week`는 서버 값이 생기면 더한다.
public enum AnalyticsUserProperty: String, CaseIterable, Sendable {
    case accountType = "account_type"
    case belt
    case stripes
    case coachRole = "coach_role"
    case loginMethod = "login_method"
    case pushEnabled = "push_enabled"
    case hasCompRecord = "has_comp_record"
    case hasGym = "has_gym"

    /// 서버 계정 구분(MEMBER · OPERATOR · INTERNAL) → `account_type` 값(member · operator · internal).
    /// 사전에 없는 값은 nil — 모르는 값을 GA에 새 분류로 쌓지 않는다.
    public static func accountTypeValue(_ serverValue: String?) -> String? {
        guard let value = serverValue?.lowercased(), ["member", "operator", "internal"].contains(value) else { return nil }
        return value
    }
}

// MARK: - 사전 검사

/// GA가 조용히 버리거나 잘라 내는 값을 보내기 전에 거른다. 위반한 기록은 보내지 않는다.
public enum AnalyticsValidation {
    static let maxNameLength = 40
    /// `surface`를 포함한 꼬리표 수
    static let maxParameterCount = 25
    static let maxParameterValueLength = 100
    static let maxUserPropertyNameLength = 24
    static let maxUserPropertyValueLength = 36
    static let reservedPrefixes = ["firebase_", "google_", "ga_"]
    static let surfaceKey = "surface"

    /// 위반 내용. 비어 있으면 보낼 수 있다.
    public static func violations(of event: AnalyticsEvent) -> [String] {
        var problems = nameViolations(event.name.rawValue, maxLength: maxNameLength)
        if event.parameters.count + 1 > maxParameterCount {
            problems.append("꼬리표 \(event.parameters.count + 1)개 > \(maxParameterCount)")
        }
        for (key, value) in event.parameters.sorted(by: { $0.key < $1.key }) {
            if key == surfaceKey {
                problems.append("'\(surfaceKey)'는 클라이언트가 붙인다")
            }
            problems += nameViolations(key, maxLength: maxNameLength)
            if case let .string(text) = value, text.count > maxParameterValueLength {
                problems.append("'\(key)' 값 \(text.count)자 > \(maxParameterValueLength)")
            }
        }
        return problems
    }

    public static func violations(of property: AnalyticsUserProperty, value: String?) -> [String] {
        var problems = nameViolations(property.rawValue, maxLength: maxUserPropertyNameLength)
        if let value, value.count > maxUserPropertyValueLength {
            problems.append("'\(property.rawValue)' 값 \(value.count)자 > \(maxUserPropertyValueLength)")
        }
        return problems
    }

    /// 영문자로 시작하고 영문자 · 숫자 · 밑줄만, 길이 제한, 예약 접두어 금지.
    private static func nameViolations(_ name: String, maxLength: Int) -> [String] {
        var problems: [String] = []
        if name.isEmpty || name.count > maxLength {
            problems.append("'\(name)' 길이 \(name.count)자 (1~\(maxLength))")
        }
        let isAllowed = name.first.map { $0.isASCII && $0.isLetter } == true
            && name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
        if !isAllowed {
            problems.append("'\(name)' 영문자로 시작하는 영문 · 숫자 · 밑줄만")
        }
        if let prefix = reservedPrefixes.first(where: { name.hasPrefix($0) }) {
            problems.append("'\(name)' 금지 접두어 \(prefix)")
        }
        return problems
    }
}
