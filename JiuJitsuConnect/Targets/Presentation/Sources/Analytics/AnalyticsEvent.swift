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

        // 푸시 · 링크로 열기(#427)
        case pushOpen = "push_open"
        case deeplinkOpen = "deeplink_open"

        // 프로필 · MY(#429). belt_update · belt_prompt는 웹과 같이 쓴다(아래 웹 목록).
        case profileView = "profile_view"
        case profileEdit = "profile_edit"

        // 대회 기록(#454)
        case competitionRecordStart = "competition_record_start"
        case competitionRecordSave = "competition_record_save"

        // 오류 · 화면 속도(#431). error_shown은 웹과 같이 쓴다(아래 웹 목록).
        case screenLoad = "screen_load"

        // 설정(#430)
        case notificationSettingChange = "notification_setting_change"
        case supportContact = "support_contact"

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

    /// GA에 숫자로 보내는 꼬리표(측정항목 · 측정값). 나머지 `.int`는 보낼 때 문자열로 바꾼다 —
    /// GA는 앱 이벤트의 정수 값을 이벤트 범위 맞춤 측정기준에 넣지 않아 `page` 같은 꼬리표가 `(not set)`이 된다(#487).
    public static let numericParameterKeys: Set<String> = ["load_ms", "metric_value"]

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
    /// 앱이 열린 입구(사전 "from 값"). `app_open` · `deeplink_open`의 `from`이 같이 쓴다.
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

    /// 앱이 꺼져 있다 켜졌나(cold), 백그라운드에서 돌아왔나(warm). `app_open` · `push_open` · `deeplink_open`이 같이 쓴다.
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

    /// 로그인 화면이 열린 입구(사전 "from 값" 중 로그인).
    public enum LoginEntry: String, Sendable {
        /// 앱 첫 로그인 화면
        case launch
        /// 로그인 안내 · 만료 안내의 [로그인]
        case loginPrompt = "login_prompt"
        /// 웹이 바로 연 로그인 모달
        case webModal = "web_modal"
        /// 비로그인으로 누른 '내 기록에 남기기'
        case record
        case myProfile = "my_profile"
        case settings
    }

    /// 로그인 안내 이유(사전 "로그인 안내"). 웹이 보낸 값은 이 목록에 있는 것만 싣는다 — 외부 입력이 GA에 새 분류로 쌓이지 않게.
    /// 로그인 안내 알럿의 이유별 제목(#392)도 이 목록을 쓴다 — 값을 더하면 `AppTabFeature.loginPromptTitle`의 문구도 정한다.
    public enum LoginReason: String, Sendable {
        case write, comment, reply, like, save, vote, interest
        case interestFilter = "interest_filter"
        case alert
        case infoReport = "info_report"
        case record, report, block
        case myTab = "my_tab"
        case profile
        case sessionExpired = "session_expired"
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
    public static func loginPromptView(reason: LoginReason?, from: String?) -> Self {
        Self(.loginPromptView, parameters: strings(["reason": reason?.rawValue, "from": from]))
    }

    public static func loginStart(method: LoginMethod, from: LoginEntry?, reason: LoginReason?) -> Self {
        Self(.loginStart, parameters: strings(["method": method.rawValue, "from": from?.rawValue, "reason": reason?.rawValue]))
    }

    /// `restored`: 탈퇴 유예 중 다시 로그인해 탈퇴가 취소됨.
    public static func login(method: LoginMethod?, from: LoginEntry?, restored: Bool) -> Self {
        Self(.login, parameters: strings(["method": method?.rawValue, "from": from?.rawValue, "restored": flag(restored)]))
    }

    public static func loginFail(method: LoginMethod?, reason: LoginFailReason) -> Self {
        Self(.loginFail, parameters: strings(["method": method?.rawValue, "reason": reason.rawValue]))
    }

    public static func signUp(method: LoginMethod?, marketing: Bool?, from: LoginEntry?) -> Self {
        Self(.signUp, parameters: strings(["method": method?.rawValue, "marketing": marketing.map(flag), "from": from?.rawValue]))
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

    /// 푸시 · 알림함 항목의 종류(사전 `notice_type`). 서버 `FcmPushType` 이름의 소문자다.
    public enum NoticeType: String, Sendable {
        case newComments = "new_comments"
        case newChildComments = "new_child_comments"
        case contentsLike = "contents_like"
        case commentsLike = "comments_like"
        case competitionEarlyBirdDeadline = "competition_early_bird_deadline"
        case competitionRegistrationDeadline = "competition_registration_deadline"

        /// 서버 값(`NEW_COMMENTS` 등). 사전에 없는 값은 nil — 새 종류가 GA에 새 분류로 쌓이지 않게.
        public init?(serverValue: String?) {
            guard let value = serverValue?.lowercased() else { return nil }
            self.init(rawValue: value)
        }
    }

    /// 푸시 · 링크로 연 대상의 종류(사전 `content_type` 중 앱이 여는 것).
    public enum OpenContentType: String, Sendable {
        case post
        case balanceGame = "balance_game"
        case competition
    }

    /// `noticeType` · `contentType`은 모르면 싣지 않는다(구버전 서버 · 새 종류). 열림 수는 남긴다.
    public static func pushOpen(noticeType: NoticeType?, contentType: OpenContentType?, appState: AppState) -> Self {
        Self(.pushOpen, parameters: strings([
            "notice_type": noticeType?.rawValue,
            "content_type": contentType?.rawValue,
            "app_state": appState.rawValue
        ]))
    }

    /// `from`: 유니버설 링크(deeplink) · 앱 주소(scheme) · 공유 링크(share_link).
    public static func deeplinkOpen(contentType: OpenContentType, appState: AppState, from: OpenSource) -> Self {
        Self(.deeplinkOpen, parameters: strings([
            "content_type": contentType.rawValue,
            "app_state": appState.rawValue,
            "from": from.rawValue
        ]))
    }

    // MARK: 대회 기록 (#454)

    /// 대회 기록 추가 화면이 열린 입구(사전 "from 값"). 웹 요청은 어느 배너든 record — 배너는 웹 `banner_click`이 남긴다.
    public enum CompetitionRecordEntry: String, Sendable {
        /// MY "대회 추가"
        case myProfile = "my_profile"
        /// MY "부문 추가"
        case divisionAdd = "division_add"
        /// 웹의 '내 기록에 남기기'(`OPEN_COMPETITION_RECORD`)
        case record
    }

    /// 대회 기록 결과(사전 `medal`).
    public enum Medal: String, Sendable {
        case gold, silver, bronze, participation
    }

    /// 대회명 입력 방법(사전 `method`). 등록된 대회와 이어졌으면(목록에서 고름 · 웹이 넘겨줌) autocomplete.
    public enum CompetitionNameMethod: String, Sendable {
        case autocomplete
        case typed
    }

    /// `competitionId`: 등록된 대회와 이어졌을 때만.
    public static func competitionRecordStart(from entry: CompetitionRecordEntry, competitionId: Int?) -> Self {
        Self(.competitionRecordStart, parameters: strings([
            "from": entry.rawValue,
            "competition_id": competitionId.map(competitionIDValue)
        ]))
    }

    /// method는 이어진 대회가 있는지로 정한다 — 이어졌으면 autocomplete, 직접 친 이름이면 typed.
    public static func competitionRecordSave(from entry: CompetitionRecordEntry, medal: Medal, competitionId: Int?) -> Self {
        let method: CompetitionNameMethod = competitionId == nil ? .typed : .autocomplete
        return Self(.competitionRecordSave, parameters: strings([
            "from": entry.rawValue,
            "medal": medal.rawValue,
            "competition_id": competitionId.map(competitionIDValue),
            "method": method.rawValue
        ]))
    }

    /// 사전 `competition_id` 모양(`comp_45`).
    static func competitionIDValue(_ id: Int) -> String {
        "comp_\(id)"
    }

    /// nil 값은 꼬리표에서 뺀다.
    static func strings(_ values: [String: String?]) -> [String: Value] {
        values.compactMapValues { $0.map(Value.string) }
    }

    private static func flag(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}

// MARK: - 신고 · 차단 (#428)

extension AnalyticsEvent {
    /// 신고 사유(사전 `reason` 중 신고). 서버 신고 사유 코드의 소문자 — 웹 글 · 댓글 신고(FE #580)도 같은 규칙으로 맞춘다.
    /// 사전 6개 밖의 `rights_violation` · `illegal_filming`도 그대로 싣는다: 급히 처리해야 하는 신고를 '기타'와 나눠 받는
    /// 사유라(FE #514) other로 합치면 GA에서 그 구분이 사라진다.
    public enum ReportReason: String, Sendable {
        case spam, abuse, adult, harassment, incitement
        case rightsViolation = "rights_violation"
        case illegalFilming = "illegal_filming"
        case other

        /// 서버 값(`ABUSE` 등). 모르는 값은 nil — 새 사유가 GA에 새 분류로 쌓이지 않게.
        public init?(serverValue: String) {
            self.init(rawValue: serverValue.lowercased())
        }
    }

    /// 신고 제출 성공(이미 신고한 회원 포함). 앱이 신고하는 대상은 회원뿐이라 content_type은 user.
    /// `reason`은 모르면 싣지 않는다 — 신고 수는 남긴다. `from`: 신고한 곳(사전 "from 값").
    public static func reportSubmit(reason: ReportReason?, from: String) -> Self {
        Self(.reportSubmit, parameters: strings([
            "content_type": "user",
            "reason": reason?.rawValue,
            "from": from
        ]))
    }

    /// 차단(on) · 차단 해제(off) 성공. `from`: 차단한 곳(사전 "from 값").
    public static func userBlock(blocked: Bool, from: String) -> Self {
        Self(.userBlock, parameters: strings([
            "state": blocked ? "on" : "off",
            "from": from
        ]))
    }
}

// MARK: - 프로필 · MY (#429)

extension AnalyticsEvent {
    /// MY 항목 저장의 종류(사전 `action`). 대회 고정 해제는 사전에 값이 없어 남기지 않는다.
    public enum ProfileEditAction: String, Sendable {
        case add, edit, delete, pin, reorder
    }

    /// 사진 출처(사전 `method`).
    public enum PhotoMethod: String, Sendable {
        case album, camera
    }

    /// 띠 저장이 어떤 변화인가(사전 `change`). 띠를 내리거나 같은 값으로 다시 저장하면 correction.
    public enum BeltChange: String, Sendable {
        case firstSet = "first_set"
        case promotion
        case stripeUp = "stripe_up"
        case correction
    }

    /// 띠를 저장한 곳(사전 "from 값").
    public enum BeltUpdateEntry: String, Sendable {
        /// MY 띠 시트
        case myProfile = "my_profile"
        /// 다른 회원 프로필 위의 띠 묻기 시트
        case beltPrompt = "belt_prompt"
    }

    /// 띠 묻기 시트가 뜸(view)과 답(사전 `action`). 바깥을 눌러 닫은 것도 later다.
    public enum BeltPromptAction: String, Sendable {
        case view, save, later
    }

    /// `from`: 프로필을 연 곳(사전 "from 값"). 모르면 싣지 않는다.
    public static func profileView(from: String?) -> Self {
        Self(.profileView, parameters: strings(["from": from]))
    }

    /// `method`: 사진 · 인증 사진을 고른 방법. 그 밖의 항목과 사진 삭제는 싣지 않는다.
    public static func profileEdit(_ section: ProfileSection, action: ProfileEditAction, method: PhotoMethod? = nil) -> Self {
        Self(.profileEdit, parameters: strings([
            "section": section.rawValue,
            "action": action.rawValue,
            "method": method?.rawValue
        ]))
    }

    /// `belt`: 띠 소문자(사용자 속성 `belt`와 같은 값), `stripes`: 그랄 수 0~4.
    public static func beltUpdate(change: BeltChange, belt: String, stripes: Int, from: BeltUpdateEntry) -> Self {
        Self(.beltUpdate, parameters: [
            "change": .string(change.rawValue),
            "belt": .string(belt),
            "stripes": .int(stripes),
            "from": .string(from.rawValue)
        ])
    }

    /// 앱의 띠 묻기 시트는 다른 회원 프로필에만 뜬다(웹은 글 · 댓글 등록 직후, FE #582).
    public static func beltPrompt(_ action: BeltPromptAction) -> Self {
        Self(.beltPrompt, parameters: [
            "action": .string(action.rawValue),
            "from": .string(NativeScreen.userProfile.rawValue)
        ])
    }
}

// MARK: - 이름 없는 누름 (#432)

extension AnalyticsEvent {
    /// 이름 붙은 이벤트가 없는 앱 버튼(사전 `element`, `화면.요소`). 웹 버튼은 웹이 `data-ga`로 남긴다(FE #584).
    public enum UIElement: String, Sendable {
        case homeSearchButton = "home.search_button"
        case homeNotificationButton = "home.notification_button"
        case competitionNotificationButton = "competition.notification_button"
        case homeScrollTop = "home.scroll_top"
        case competitionScrollTop = "competition.scroll_top"
        case homeTabReselect = "home.tab_reselect"
        case competitionTabReselect = "competition.tab_reselect"
        case homePullRefresh = "home.pull_refresh"
        case competitionPullRefresh = "competition.pull_refresh"
        case tabBarMy = "tab_bar.my"
    }

    public static func uiClick(_ element: UIElement) -> Self {
        Self(.uiClick, parameters: ["element": .string(element.rawValue)])
    }
}

// MARK: - 설정 (#430)

extension AnalyticsEvent {
    /// 알림 설정 그룹(사전 `section` 중 알림 설정).
    public enum NotificationSection: String, Sendable {
        case security, service, community, competition, marketing
    }

    /// 문의한 곳(사전 "from 값").
    public enum SupportContactEntry: String, Sendable {
        case settings
        /// 관장 사범 인증 시트의 '인증 정보 변경 문의하기'
        case ownerCert = "owner_cert"
    }

    /// 문의 결과(사전 `result`). 메일 앱을 열지 못하면 주소를 복사해 둔다.
    public enum SupportContactResult: String, Sendable {
        case opened, copied
    }

    /// 저장 응답으로 확인된 그룹 하나의 켬 · 끔.
    public static func notificationSettingChange(_ section: NotificationSection, isOn: Bool) -> Self {
        Self(.notificationSettingChange, parameters: [
            "section": .string(section.rawValue),
            "state": .string(isOn ? "on" : "off")
        ])
    }

    public static func supportContact(from: SupportContactEntry, result: SupportContactResult) -> Self {
        Self(.supportContact, parameters: [
            "from": .string(from.rawValue),
            "result": .string(result.rawValue)
        ])
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
