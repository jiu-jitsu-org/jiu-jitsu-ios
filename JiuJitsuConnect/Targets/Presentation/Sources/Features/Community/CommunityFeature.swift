//
//  CommunityFeature.swift
//  Presentation
//
//  커뮤니티 탭 컨테이너 — 외부 웹 페이지를 WKWebView로 렌더링한다.
//  실제 커뮤니티 기능(피드/글쓰기 등)은 웹쪽에서 구현되며,
//  여기서는 URL 로딩 상태(로딩/에러/재시도)만 TCA로 관리한다.
//

import ComposableArchitecture
import CoreKit
import Domain
import Foundation

@Reducer
public struct CommunityFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        // 새 알림 여부 조회. 진입·복귀·포그라운드가 겹쳐 들어와도 마지막 요청만 반영한다.
        case unreadNotification
        // 연결 문제로 실패한 피드가 연결이 돌아오길 지켜봄(#396).
        case connectionWatch
    }

    /// 테스트용 도메인 변경 다이얼로그에서 한 번에 전환할 수 있는 서버 후보.
    /// 값은 Info.plist에 구성별로 주입되며, Release 구성에서는 비어 있다(버튼도 노출되지 않음).
    public enum DebugServer: String, CaseIterable, Sendable, Equatable {
        case prod
        case dev

        var title: String {
            switch self {
            case .prod: return "운영 서버"
            case .dev: return "개발 서버"
            }
        }

        private var infoPlistKey: String {
            switch self {
            case .prod: return "DEBUG_WEB_URL_PROD"
            case .dev: return "DEBUG_WEB_URL_DEV"
            }
        }

        var urlString: String {
            WebEnvironment.string(forKey: infoPlistKey)
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 이 목록 웹뷰가 마지막으로 알린 화면(screen_view, #425). 보일 때 루트 분석 리듀서가 기록한다.
        var analyticsScreen: AnalyticsEvent?
        /// 화면 이름(screen_view)을 기다리는 로드 시간(#431).
        var pendingScreenLoad: WebScreenLoad?
        var url: URL?
        // 같은 URL로 재시도 시 View가 reload를 인지하도록 토큰을 갱신한다.
        var loadToken: UUID = UUID()
        // 값이 바뀔 때마다 View가 리스트 웹뷰를 맨 위로 올린다(#229). 처음엔 nil이라 움직이지 않는다.
        var scrollToTopToken: UUID?
        var isLoading: Bool = true
        var hasError: Bool = false
        // 연결 문제로 실패했는지와 연결이 돌아오면 한 번 다시 불러오기(#396).
        var connectionRetry = WebConnectionRetry()

        // 현재 백엔드 access token. 로그인 상태면 값이 있고, 게스트면 nil.
        // WEBVIEW_READY 핸드셰이크 시 초기 로그인 상태 동기화에 사용한다.
        // (정책: 웹에는 accessToken만 전달, refreshToken은 네이티브 Keychain에만 보관)
        var accessToken: String?
        // 네이티브 → 웹으로 보낼 브릿지 메시지 대기열. View가 evaluateJavaScript로
        // 전달한 뒤 outboundDelivered로 제거한다.
        var outbox: [WebBridgeOutboundEnvelope] = []

        // 웹이 요청한 확인 알럿/선택 시트(표시 중이면 non-nil). 리스트 웹뷰의 다이얼로그는
        // GNB·하단 탭바까지 덮어야 해 AppTabView(최상위)가 이 상태를 읽어 그린다.
        // 한 번에 하나만 표시한다(동시 요청은 즉시 dismiss로 회신).
        var pendingConfirmDialog: ConfirmDialogPayload?
        var pendingSelectSheet: SelectSheetPayload?

        // GNB 종 아이콘의 새 알림 점. 안 읽은 알림이 하나라도 있으면 true.
        var hasUnreadNotification = false

        // 홈 웹이 알린 머리줄 색(HOME_HEADER_TINT, `#RRGGBB`). 맨 위 진한 띠가 보이는 동안만 값이 있고, nil이면 흰 머리줄.
        var headerTint: String?

        // 테스트용 웹뷰 도메인 변경 입력 다이얼로그 상태. (DEBUG/BETA 빌드에서만 노출)
        var isDebugURLAlertPresented = false
        var debugURLInput = ""

        // OPEN_SUBVIEW(push)로 쌓이는 게시글 상세 서브뷰 스택. 중첩 OPEN_SUBVIEW도 여기에 push된다.
        var path = StackState<Path.State>()
        // OPEN_SUBVIEW(modal)로 띄우는 상세 서브뷰(모달 루트).
        @Presents var detailCover: CommunityDetailFeature.State?
        // 모달 내부에서의 중첩 OPEN_SUBVIEW가 쌓이는 별도 스택(모달 위 NavigationStack 전용).
        var coverPath = StackState<Path.State>()

        // 알림함은 로그인 사용자 전용이라 비로그인이면 종 아이콘 자체를 숨긴다(알림함 정책).
        var isNotificationButtonVisible: Bool { accessToken != nil }

        // 피드 위에 상세가 떠 있으면 피드는 가려져 있다. 전체 화면 덮개(detailCover)는 아래 뷰에 onDisappear를 보내지 않아 여기서 거른다.
        var isWatchingConnection: Bool {
            connectionRetry.isWatchingConnection && path.isEmpty && detailCover == nil
        }

        public init(accessToken: String? = nil) {
            self.accessToken = accessToken
            let url = CommunityFeature.makeCommunityURL()
            self.url = url
            // URL 자체를 만들 수 없으면 WKWebView가 생성되지 않아 로딩 콜백이 영영 오지 않는다.
            // 사용자에게 무한 로딩 대신 재시도 오버레이를 보여주기 위해 에러 상태로 초기화한다.
            if url == nil {
                self.isLoading = false
                self.hasError = true
            }
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        // 부모(AppTabFeature)가 세션 변화를 주입해 웹뷰에 전파시키는 통로.
        case session(SessionAction)
        // 부모(AppTabFeature)가 딥링크(공유 링크·푸시 탭)를 주입해 상세로 보내는 통로.
        case deepLink(DeepLink)
        /// 다른 회원 프로필 열기 — 웹의 작성자 탭(`OPEN_USER_PROFILE`, isMe=false)이 보낸다(#116)
        case openUserProfile(userId: Int)
        // 부모가 새 알림 점을 다시 조회시킨다 — 대회 탭의 종도 이 값을 그린다(#258).
        case unreadNotificationRefreshRequested

        // 게시글 상세 서브뷰 네비게이션.
        case path(StackAction<Path.State, Path.Action>)
        case coverPath(StackAction<Path.State, Path.Action>)
        case detailCover(PresentationAction<CommunityDetailFeature.Action>)

        public enum ViewAction: Sendable {
            case onAppear
            // 다른 탭에서 커뮤니티 탭으로 돌아옴. 탭 컨테이너가 뷰를 유지해 onAppear가 다시 오지 않으므로 부모가 보낸다.
            case tabEntered
            // 이미 커뮤니티 탭인데 하단 탭바의 홈 아이콘을 다시 누름.
            case tabReselected
            // 앱이 포그라운드로 복귀.
            case sceneBecameActive
            case retryTapped
            // 피드가 사용자에게 보이게 됨 · 가려짐(다른 탭 · 위에 쌓인 화면 · 백그라운드). 보일 때만 연결을 지켜본다(#396).
            case visibilityChanged(Bool)
            case notificationTapped
            case searchTapped

            // MARK: 브릿지 다이얼로그 결과 (AppTabView가 그린 알럿/시트 → Feature로 회신)
            // 확인 알럿의 [확인]/[취소] 버튼 탭.
            case confirmDialogButtonTapped(ConfirmDialogOutcome)
            // 확인 알럿이 버튼 외로 닫힘(바깥 탭 등). 버튼으로 이미 처리됐으면 무시된다.
            case confirmDialogDismissed
            // 선택 시트 제출(선택 value + 자유 입력).
            case selectSheetSubmitted(value: String, customText: String?)
            // 선택 시트 제출 없이 닫힘(드래그·딤 탭).
            case selectSheetDismissed

            // MARK: 테스트용 웹뷰 도메인 변경
            // IP/도메인을 입력받아 즉시 해당 주소의 웹뷰를 다시 로드한다. (DEBUG/BETA 전용)
            case debugChangeDomainTapped
            case debugURLInputChanged(String)
            case debugURLApplyTapped
            case debugServerTapped(DebugServer)
            case debugURLAlertDismissed
            // 입력한 주소를 실제 유니버설 링크와 같은 파서·라우팅에 태워 본다.
            case debugDeepLinkOpenTapped
        }

        public enum InternalAction: Sendable {
            case loadingStarted
            case loadingFinished
            case loadingFailed(WebLoadFailure)
            // 연결 문제로 실패한 뒤 연결이 돌아옴(#396) → 한 번 저절로 다시 불러온다.
            case connectionRestored
            case screenLoadMeasured(WebScreenLoad)
            // 당겨서 새로고침 시작(이때는 loadingStarted가 오지 않는다). 분석 기록(homePullRefresh)이 센다.
            case refreshStarted
            // 웹뷰가 AppBridge로 보내온 인바운드 메시지(WKScriptMessageHandler 경유).
            case bridgeMessageReceived(WebBridgeInboundMessage)
            // View가 outbox의 메시지를 evaluateJavaScript로 전달 완료했음을 통지.
            case outboundDelivered(id: UUID)
            case unreadNotificationResponse(TaskResult<Bool>)
            // COMPETITION_ALERTS_ENABLED를 받고 기기 알림 상태를 봄(#395). requestId가 있으면 리스트 웹에 답한다.
            case competitionAlertsChecked(requestId: String?, DeviceNotificationCheck)
            // CONTENT_ALERTS_ENABLED(글 · 밸런스 게임 종)를 받고 기기 알림 상태를 봄(#466). 리스트 웹에 늘 답한다.
            case contentAlertsChecked(requestId: String, DeviceNotificationCheck)
        }

        public enum DelegateAction: Sendable {
            // 비로그인 행위 시도 → 부모가 "로그인이 필요해요" 안내 알럿을 띄운다.
            case loginPromptRequested(reason: String?)
            // 비로그인 행위 시도 → 부모가 로그인 모달을 즉시 띄운다(다이렉트).
            case loginModalRequested(reason: String?)
            // 웹 주도 로그아웃 요청(선택) → 부모가 네이티브 로그아웃을 수행한다.
            case logoutRequested
            // 웹뷰 토큰 만료 → 부모가 네이티브 refresh로 갱신 후 결과를 웹에 주입한다.
            case tokenRefreshRequested
            // 웹에서 내 이름 탭(#116) → 부모가 MY 화면을 이 스택에 push한다(#197).
            // MY 화면을 만들려면 로그인 정보(authInfo)가 필요해 부모(AppTab)가 직접 쌓는다.
            case myProfileRequested
            // 테스트용 '딥링크로 열기'(DEBUG/BETA) → 부모가 실제 유니버설 링크와 같은 경로(.deepLink)로 보낸다.
            case debugDeepLinkRequested(DeepLink)
            // 홈 웹(피드·글 상세·알림함)의 관심 대회 '알림 받기' · 상세 종의 기기 알림 상태(#257 · #395) → 부모가 꺼짐 안내 · 토큰 등록을 맡는다.
            case competitionAlertsChecked(DeviceNotificationCheck)
            // 이 스택에 쌓인 MY · 남의 프로필 띠 묻기에서 내 프로필을 저장함 → 부모가 열린 웹뷰 모두에 PROFILE_UPDATED를 보낸다.
            case profileUpdated
            // 이 스택에 쌓인 남의 프로필에서 회원을 차단·해제함(#328) → 부모가 열린 웹뷰 모두에 USER_BLOCK_CHANGED를 보낸다.
            case userBlockChanged(userId: Int, blocked: Bool)
            // 홈에 쌓인 대회 상세의 '커뮤니티에서 더 보기'(#304) → 부모가 홈에 쌓인 화면을 닫아 피드를 보인다.
            // 대회 번호가 있으면 그 대회 글만(#437), 카테고리 번호가 있으면 그 카테고리 탭으로(#480) 피드를 다시 연다.
            case homeFeedRequested(HomeFeedFilter?)
            // 홈에 쌓인 끝난 대회 상세의 '내 기록에 남기기'(#304) → 부모가 프로필을 보고 기록 추가를 그 상세 위에 쌓는다.
            case competitionRecordRequested(OpenCompetitionRecordPayload)
            // 홈 웹에서 글 · 댓글을 올림(#333) → 부모(AppTab)가 알림 권한 안내를 띄울지 정한다.
            case contentCreated
        }

        /// 부모가 세션 상태 변화를 알려주면 그에 맞는 아웃바운드 메시지를 웹에 주입한다.
        public enum SessionAction: Sendable {
            case loggedIn(accessToken: String)
            /// AUTH_TOKEN_REFRESH_REQUEST에 대한 갱신 성공 응답. `loggedIn`(수동 동기화)과 달리
            /// 토큰 값이 같아도 반드시 웹에 회신한다 — 요청한 웹뷰가 응답을 기다리고 있기 때문이다.
            case tokenRefreshed(accessToken: String)
            case loginCancelled
            case loggedOut
            case sessionExpired
            /// MY에서 프로필을 저장함 → PROFILE_UPDATED
            case profileUpdated
            /// 남의 프로필에서 회원을 차단·해제함 → USER_BLOCK_CHANGED
            case userBlockChanged(userId: Int, blocked: Bool)
            /// 대회 상세에서 연 기록 추가를 저장함(#397) → COMPETITION_RECORD_SAVED
            case competitionRecordSaved(competitionId: String)
        }
    }

    @Reducer
    public enum Path: Sendable {
        case detail(CommunityDetailFeature)
        case userProfile(UserProfileFeature)
        /// 커뮤니티에서 내 이름을 눌러 연 MY 화면(#197). 탭의 MY와 같은 화면이고 왼쪽 위에 뒤로가기가 붙는다.
        case myProfile(MyProfileFeature)
        /// 홈에서 연 대회 상세의 '내 기록에 남기기'로 여는 대회 기록 추가(#304). 저장은 프로필을 아는 부모(AppTab)가 한다.
        case competitionInfo(CompetitionInfoFeature)
    }

    /// 홈 리스트 웹뷰가 알리는 기능. 맨 위 진한 띠가 보이는 동안 머리줄 색을 앱이 맞춘다.
    static let listCapabilities: [WebBridgeCapability] = [.homeHeaderTint]

    /// 홈에 쌓이는 웹이 알리는 기능. 피드·글 상세·알림함에서 연 대회 상세도 대회 탭과 같이
    /// '커뮤니티에서 더 보기'·'내 기록에 남기기'를 네이티브가 받는다(#304).
    static let subviewCapabilities: [WebBridgeCapability] = [
        .pickPhotos,
        .openHomeFeed,
        .openCompetitionRecord
    ]

    static func subview(url: URL, title: String? = nil, accessToken: String?) -> CommunityDetailFeature.State {
        CommunityDetailFeature.State(
            url: url,
            title: title,
            accessToken: accessToken,
            isTabRoot: false,
            capabilities: subviewCapabilities
        )
    }

    /// 중첩 서브뷰가 어느 컨테이너(푸시 스택 / 모달 내부 스택)에서 올라왔는지 구분한다.
    private enum SubviewContainer {
        case push
        case modal
    }

    @Dependency(\.noticeClient) var noticeClient
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.notificationPermissionClient) var notificationPermissionClient
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.networkPathClient) var networkPathClient
    @Dependency(\.continuousClock) var clock

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                if state.url == nil {
                    state.url = Self.makeCommunityURL()
                }
                return refreshHeaderState(state)

            case .view(.tabEntered), .view(.sceneBecameActive):
                return refreshHeaderState(state)

            case .view(.tabReselected):
                // 상세 등이 위에 떠 있으면 가려진 피드를 움직이지 않는다.
                guard state.path.isEmpty, state.coverPath.isEmpty, state.detailCover == nil else { return .none }
                state.scrollToTopToken = UUID()
                return .none

            // 알림함은 iOS/Android 공용 웹 화면이다. 상세와 같은 chromeless 서브뷰로 열어
            // 알림 항목 탭(OPEN_SUBVIEW)·뒤로가기(CLOSE_SUBVIEW)를 기존 브릿지 흐름 그대로 쓴다.
            // `PushActionRouter`는 푸시 탭 전용으로 남는다. (#45)
            case .view(.notificationTapped):
                guard
                    state.isNotificationButtonVisible,
                    let base = state.url,
                    let url = NotificationInbox.url(base: base)
                else { return .none }
                state.path.append(.detail(Self.subview(url: url, accessToken: state.accessToken)))
                return .none

            // 글 검색은 웹 화면이다(jiu-jitsu-frontend#591, #435). 알림함처럼 서브뷰로 열어, 결과 글은 그 위에 쌓이고
            // 뒤로가기는 검색 결과 → 홈 순서로 돌아온다. 비로그인도 쓸 수 있어 로그인을 묻지 않는다.
            case .view(.searchTapped):
                guard let base = state.url, let url = Self.searchURL(base: base) else { return .none }
                // 연타로 검색 화면이 두 겹 쌓이지 않게 — 이미 맨 위가 검색이면 그대로 둔다.
                if let id = state.path.ids.last, case let .detail(top)? = state.path[id: id], WebOrigin.isSamePage(top.url, url) {
                    return .none
                }
                state.path.append(.detail(Self.subview(url: url, accessToken: state.accessToken)))
                return .none

            case .view(.retryTapped):
                state.connectionRetry.reset()
                Self.retryLoad(&state)
                return .none

            case let .view(.visibilityChanged(isVisible)):
                state.connectionRetry.screenVisibilityChanged(isVisible)
                return .none

            case .internal(.connectionRestored):
                guard state.isWatchingConnection else { return .none }
                Log.trace("연결이 돌아와 홈 피드를 다시 불러옴", category: .network, level: .info)
                state.connectionRetry.autoReloaded()
                Self.retryLoad(&state)
                return .none

            // MARK: - 테스트용 웹뷰 도메인 변경

            case .view(.debugChangeDomainTapped):
                // 현재 적용된 주소를 입력 필드 기본값으로 채워 수정 출발점을 제공한다.
                state.debugURLInput = state.url?.absoluteString ?? ""
                state.isDebugURLAlertPresented = true
                return .none

            case let .view(.debugURLInputChanged(text)):
                state.debugURLInput = text
                return .none

            case .view(.debugURLApplyTapped):
                state.isDebugURLAlertPresented = false
                Self.setDebugOverrideURLString(Self.normalizedURLString(state.debugURLInput))
                Self.reloadCommunity(&state)
                return .none

            case let .view(.debugServerTapped(server)):
                state.isDebugURLAlertPresented = false
                // 고른 서버가 이 빌드 구성의 기본값과 같으면 오버라이드를 지운다.
                // 그래야 이후 구성의 WEB_URL이 바뀌어도 옛 주소에 고정되지 않는다.
                let selected = server.urlString
                let isDefault = !selected.isEmpty && selected == Self.defaultWebURLString
                Self.setDebugOverrideURLString(isDefault ? nil : Self.normalizedURLString(selected))
                Self.reloadCommunity(&state)
                return .none

            case .view(.debugURLAlertDismissed):
                state.isDebugURLAlertPresented = false
                return .none

            case .view(.debugDeepLinkOpenTapped):
                // AASA 배포 전에도 파싱·라우팅을 확인하기 위한 통로. 콜드 스타트 경로는
                // 재현하지 못하므로 실기기 링크 탭 검증은 별도로 필요하다.
                state.isDebugURLAlertPresented = false
                let raw = state.debugURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard
                    let url = URL(string: raw),
                    let link = DeepLinkParser.parse(url)
                else {
                    Log.trace("테스트 딥링크 파싱 실패: \(raw)", category: .system, level: .error)
                    return .none
                }
                // 대회 링크는 대회 탭이 열어야 하므로 실제 링크처럼 부모(AppTab)의 라우팅을 거친다.
                return .send(.delegate(.debugDeepLinkRequested(link)))

            // MARK: - 브릿지 다이얼로그 결과 (→ 웹 회신)

            case let .view(.confirmDialogButtonTapped(outcome)):
                guard let pending = state.pendingConfirmDialog else { return .none }
                state.pendingConfirmDialog = nil
                Self.enqueue(.confirmDialogResult(requestId: pending.requestId, outcome: outcome), into: &state)
                return .none

            case .view(.confirmDialogDismissed):
                // 버튼 탭이면 위에서 이미 pending을 비워 여기선 무시된다(중복 회신 방지).
                guard let pending = state.pendingConfirmDialog else { return .none }
                state.pendingConfirmDialog = nil
                Self.enqueue(.confirmDialogResult(requestId: pending.requestId, outcome: .dismiss), into: &state)
                return .none

            case let .view(.selectSheetSubmitted(value, customText)):
                guard let pending = state.pendingSelectSheet else { return .none }
                state.pendingSelectSheet = nil
                Self.enqueue(
                    .selectSheetResult(requestId: pending.requestId, outcome: .submit(value: value, customText: customText)),
                    into: &state
                )
                return .none

            case .view(.selectSheetDismissed):
                guard let pending = state.pendingSelectSheet else { return .none }
                state.pendingSelectSheet = nil
                Self.enqueue(.selectSheetResult(requestId: pending.requestId, outcome: .dismiss), into: &state)
                return .none

            // 새 문서는 띠 색을 다시 알린다. 지난 색이 덮개·새 화면 위에 남지 않게 흰 머리줄로 돌린다.
            // 당겨서 새로고침은 로딩 시작을 알리지 않아 지우지 않는다 — 띠가 보이는 채라 흰색으로 깜빡이지 않게(대회 탭과 같음).
            case .internal(.loadingStarted):
                state.isLoading = true
                state.hasError = false
                state.connectionRetry.loadStarted()
                state.headerTint = nil
                return .none

            // 당겨서 새로고침 — 상태는 그대로. 분석 기록만 이 액션을 센다(AppFeature+UIClickAnalytics).
            case .internal(.refreshStarted):
                return .none

            case .internal(.loadingFinished):
                state.isLoading = false
                state.hasError = false
                state.connectionRetry.loadSucceeded()
                return .none

            case let .internal(.loadingFailed(failure)):
                state.isLoading = false
                state.hasError = true
                state.connectionRetry.loadFailed(failure)
                // 오류 화면 위에 지난 진한 머리줄이 남지 않게 한다.
                state.headerTint = nil
                WebAnalytics.loadFailed(failure, client: analyticsClient)
                return .none

            case let .internal(.screenLoadMeasured(load)):
                WebAnalytics.screenLoadMeasured(
                    load,
                    lastScreen: state.analyticsScreen,
                    pendingLoad: &state.pendingScreenLoad,
                    client: analyticsClient
                )
                return .none

            // MARK: - Web Bridge (인바운드)

            case let .internal(.bridgeMessageReceived(message)):
                switch message {
                case .webViewReady:
                    return Self.syncSessionOnReady(into: &state)

                case .pageReady:
                    // 피드 글이 그려졌으면 사진을 다 받기(didFinish) 전에 덮개를 걷는다(#261).
                    guard !state.hasError else { return .none }
                    state.isLoading = false
                    return .none

                case let .authLoginPrompt(reason):
                    return .send(.delegate(.loginPromptRequested(reason: reason)))

                case let .authLoginModal(reason):
                    return .send(.delegate(.loginModalRequested(reason: reason)))

                case .authLogoutRequest:
                    return .send(.delegate(.logoutRequested))

                case .authTokenRefresh:
                    // 웹뷰 토큰 만료 → 네이티브가 refresh를 소유하므로 부모에 갱신을 위임한다.
                    // 응답은 부모가 `.session(.tokenRefreshed)` 또는 `.session(.sessionExpired)`로 되돌려준다.
                    return .send(.delegate(.tokenRefreshRequested))

                case let .openSubview(payload):
                    return Self.openSubview(payload, from: .push, into: &state)

                case .closeSubview:
                    // 리스트 웹뷰에는 닫을 서브뷰가 없다. 상세 웹뷰의 CLOSE는 각 상세가 처리한다.
                    Log.trace("리스트 웹뷰 CLOSE_SUBVIEW 수신 — 무시", category: .network, level: .info)
                    return .none

                case .setLeaveGuard:
                    // 이탈 가드는 스와이프 백으로 닫히는 서브뷰 전용 — 탭 루트인 리스트는 스와이프 백이 없어 무시한다.
                    return .none

                case let .showConfirmDialog(payload):
                    return Self.presentConfirmDialog(payload, into: &state)

                case let .showSelectSheet(payload):
                    return Self.presentSelectSheet(payload, into: &state)

                case let .pickPhotos(payload):
                    // 리스트 웹뷰는 PICK_PHOTOS 지원을 알리지 않으므로 오지 않아야 한다. 혹시 오면
                    // 웹이 타임아웃까지 기다리지 않도록 빈 결과로 바로 회신한다.
                    Log.trace("리스트 웹뷰 PICK_PHOTOS 수신 — 빈 결과로 회신", category: .network, level: .info)
                    Self.enqueue(.photosPicked(requestId: payload.requestId, files: []), into: &state)
                    return .none

                case let .openUserProfile(payload):
                    guard payload.isMe else {
                        return .send(.openUserProfile(userId: payload.userId))
                    }
                    return .send(.delegate(.myProfileRequested))

                case let .competitionAlertsEnabled(competitionId, requestId):
                    // 홈 피드 글 속 대회 카드에서도 관심 첫 등록 시트가 뜬다(#257). 웹에 답한 뒤 부모(AppTab)가 대회 탭과 같이 안내한다(#395).
                    return checkCompetitionAlerts(competitionId: competitionId, requestId: requestId)

                case let .contentAlertsEnabled(contentId, requestId):
                    // 글 · 밸런스 게임 상세의 알림 종(#466 · jiu-jitsu-frontend#633). 대회 쪽과 같이 이 웹에 답하고 부모가 안내한다.
                    return checkContentAlerts(contentId: contentId, requestId: requestId)

                case .contentCreated:
                    return .send(.delegate(.contentCreated))

                case let .analyticsEvent(event):
                    WebAnalytics.receive(event, lastScreen: &state.analyticsScreen, client: analyticsClient)
                    WebAnalytics.logPendingScreenLoad(after: event, pendingLoad: &state.pendingScreenLoad, client: analyticsClient)
                    return .none

                case let .homeHeaderTint(hex):
                    state.headerTint = hex
                    return .none

                case .openHomeFeed, .openCompetitionRecord, .competitionHeaderTint, .setSheetOpen, .setTopGlass:
                    // 대회 화면만 알리는 신호(#250)라 홈 피드 웹에서는 오지 않아야 한다. 받을 곳이 없어 무시한다.
                    Log.trace("리스트 웹뷰 \(message) 수신 — 무시", category: .network, level: .info)
                    return .none

                case let .unknown(type):
                    // 계약에 없는 타입 — 한쪽만 먼저 배포된 경우를 대비해 무시한다.
                    Log.trace("WebBridge 미지원 메시지 무시: \(type)", category: .network, level: .info)
                    return .none
                }

            case let .internal(.competitionAlertsChecked(requestId, check)):
                if let requestId {
                    Self.enqueue(.competitionAlertsResult(requestId: requestId, deviceEnabled: check.isEnabled), into: &state)
                }
                return .send(.delegate(.competitionAlertsChecked(check)))

            case let .internal(.contentAlertsChecked(requestId, check)):
                Self.enqueue(.contentAlertsResult(requestId: requestId, deviceEnabled: check.isEnabled), into: &state)
                // 꺼짐 안내(로그인 동안 한 번, 대회와 같이 센다) · 토큰 등록은 대회 알림과 같은 경로로 AppTab이 맡는다(#466).
                return .send(.delegate(.competitionAlertsChecked(check)))

            case let .internal(.outboundDelivered(id)):
                state.outbox.removeAll { $0.id == id }
                return .none

            case let .internal(.unreadNotificationResponse(.success(hasUnread))):
                // 응답 전에 로그아웃됐다면 이전 계정의 결과를 버린다.
                guard state.isNotificationButtonVisible else { return .none }
                state.hasUnreadNotification = hasUnread
                return .none

            case let .internal(.unreadNotificationResponse(.failure(error))):
                // 점은 보조 표시라 실패를 알리지 않고 직전 값을 유지한다. 다음 진입·복귀 때 다시 조회된다.
                Log.trace("새 알림 여부 조회 실패: \(error)", category: .network, level: .error)
                return .none

            // MARK: - Session (부모 주입 → 아웃바운드)

            case let .session(.loggedIn(accessToken)):
                // 토큰 자동 갱신으로 같은 값이 반복 주입될 수 있어(동시 401 등), 변동 없으면 건너뛴다.
                guard state.accessToken != accessToken else { return .none }
                let wasGuest = state.accessToken == nil
                state.accessToken = accessToken
                Self.enqueueLoginSuccess(accessToken: accessToken, into: &state)
                Self.broadcastToDetails(.loggedIn(accessToken: accessToken), into: &state)
                // 토큰 자동 갱신으로 들어온 경우는 같은 계정이라 다시 조회하지 않는다.
                return wasGuest ? refreshHeaderState(state) : .none

            case let .session(.tokenRefreshed(accessToken)):
                // 갱신 응답은 요청한 웹뷰가 기다리고 있으므로 값이 같아도 반드시 회신한다.
                // (`loggedIn`의 중복 제거를 타면 응답이 사라져 웹이 타임아웃까지 복구 화면에 머문다)
                state.accessToken = accessToken
                WebBridge.logEvent("토큰 갱신 완료 → AUTH_LOGIN_SUCCESS(갱신 후 토큰) 회신", source: .list)
                Self.enqueueLoginSuccess(accessToken: accessToken, into: &state)
                Self.broadcastToDetails(.tokenRefreshed(accessToken: accessToken), into: &state)
                return .none

            case .session(.loginCancelled):
                // 로그인 안내는 리스트·상세 어느 웹뷰에서 요청했는지 따로 기억하지 않으므로 모두에 알린다.
                // 웹은 이 메시지에 보관한 행위만 비우므로, 요청하지 않은 웹뷰가 받아도 영향이 없다.
                Self.enqueue(.authLoginCancelled, into: &state)
                Self.broadcastToDetails(.loginCancelled, into: &state)
                return .none

            case .session(.loggedOut):
                state.accessToken = nil
                state.hasUnreadNotification = false
                Self.enqueue(.authLogout, into: &state)
                Self.broadcastToDetails(.loggedOut, into: &state)
                return .cancel(id: CancelID.unreadNotification)

            case .session(.sessionExpired):
                state.accessToken = nil
                state.hasUnreadNotification = false
                Self.enqueue(.authSessionExpired, into: &state)
                Self.broadcastToDetails(.sessionExpired, into: &state)
                return .cancel(id: CancelID.unreadNotification)

            case .session(.profileUpdated):
                Self.enqueue(.profileUpdated, into: &state)
                Self.broadcastToDetails(.profileUpdated, into: &state)
                return .none

            case let .session(.userBlockChanged(userId, blocked)):
                Self.enqueue(.userBlockChanged(userId: userId, blocked: blocked), into: &state)
                Self.broadcastToDetails(.userBlockChanged(userId: userId, blocked: blocked), into: &state)
                return .none

            case let .session(.competitionRecordSaved(competitionId)):
                Self.enqueue(.competitionRecordSaved(competitionId: competitionId), into: &state)
                Self.broadcastToDetails(.competitionRecordSaved(competitionId: competitionId), into: &state)
                return .none

            case .unreadNotificationRefreshRequested:
                return refreshUnreadNotification(state)

            // MARK: - DeepLink (부모 주입 → 게시글 상세 진입)

            case let .deepLink(link):
                return Self.openDeepLink(link, into: &state)

            case let .openUserProfile(userId):
                // 상세 모달이 떠 있으면 모달 안 스택에 쌓는다(모달을 닫으며 push하면 전환이 튄다)
                // 게스트에게는 띠를 묻지 않는다(#130)
                // 연타·중복 전달로 같은 프로필이 겹쳐 쌓이지 않게 한다(딥링크의 updateTopDetail과 같은 이유)
                let top = state.detailCover != nil ? state.coverPath.last : state.path.last
                if case let .userProfile(current)? = top, current.userId == userId { return .none }
                let profile = UserProfileFeature.State(userId: userId, canPromptBelt: state.accessToken != nil)
                if state.detailCover != nil {
                    state.coverPath.append(.userProfile(profile))
                } else {
                    state.path.append(.userProfile(profile))
                }
                return .none

            // MARK: - Subview Delegates (상세 서브뷰 → 부모)

            // 푸시 스택의 상세에서 올라온 위임.
            case let .path(.element(id: _, action: .detail(.delegate(delegate)))):
                return Self.handleDetailDelegate(delegate, from: .push, into: &state)

            // 모달 내부 스택의 상세에서 올라온 위임.
            case let .coverPath(.element(id: _, action: .detail(.delegate(delegate)))):
                return Self.handleDetailDelegate(delegate, from: .modal, into: &state)

            // 모달 루트 상세에서 올라온 위임.
            case let .detailCover(.presented(.delegate(delegate))):
                return Self.handleDetailDelegate(delegate, from: .modal, into: &state)

            // MARK: - 커뮤니티에서 연 MY 화면의 위임 (#197)

            // '커뮤니티 활동'은 탭의 MY와 달리 MY 자기 스택이 아니라 이 커뮤니티 스택에 쌓는다.
            // 그래야 그 안에서 여는 글·남의 프로필도 같은 스택에 쌓이고 뒤로가기 한 줄로 돌아온다.
            case .path(.element(id: _, action: .myProfile(.delegate(.communityActivityRequested)))):
                return Self.pushMyActivity(from: .push, into: &state)

            case .coverPath(.element(id: _, action: .myProfile(.delegate(.communityActivityRequested)))):
                return Self.pushMyActivity(from: .modal, into: &state)

            case .path(.element(id: _, action: .myProfile(.delegate(.profileUpdated)))),
                 .coverPath(.element(id: _, action: .myProfile(.delegate(.profileUpdated)))),
                 .path(.element(id: _, action: .userProfile(.delegate(.profileUpdated)))),
                 .coverPath(.element(id: _, action: .userProfile(.delegate(.profileUpdated)))):
                return .send(.delegate(.profileUpdated))

            case let .path(.element(id: _, action: .userProfile(.delegate(.blockChanged(userId, blocked))))),
                 let .coverPath(.element(id: _, action: .userProfile(.delegate(.blockChanged(userId, blocked))))),
                 let .path(.element(id: _, action: .myProfile(.delegate(.userBlockChanged(userId, blocked))))),
                 let .coverPath(.element(id: _, action: .myProfile(.delegate(.userBlockChanged(userId, blocked))))):
                return .send(.delegate(.userBlockChanged(userId: userId, blocked: blocked)))

            // 알림함에서 읽은 알림 · 글 상세를 열어 서버가 읽음 처리한 그 글의 알림(#401, backend#246)을 점에 반영한다.
            // forEach · ifLet보다 먼저 실행돼 닫히는 화면이 아직 스택에 남아 있다. 여러 화면이 한 번에 닫히기도 해 닫히는 범위 전체를 본다.
            case let .path(.popFrom(id)):
                guard
                    let index = state.path.ids.firstIndex(of: id),
                    state.path.ids[index...].contains(where: { Self.refreshesUnreadOnClose(state.path[id: $0]) })
                else { return .none }
                return refreshUnreadNotification(state)

            case let .coverPath(.popFrom(id)):
                guard
                    let index = state.coverPath.ids.firstIndex(of: id),
                    state.coverPath.ids[index...].contains(where: { Self.refreshesUnreadOnClose(state.coverPath[id: $0]) })
                else { return .none }
                return refreshUnreadNotification(state)

            // 푸시 · 링크로 연 상세 모달이 닫힘 — 모달 안 스택도 함께 닫힌다.
            case .detailCover(.dismiss):
                guard let cover = state.detailCover else { return .none }
                let closesContent = Self.refreshesUnreadOnClose(.detail(cover))
                    || state.coverPath.contains(where: { Self.refreshesUnreadOnClose($0) })
                return closesContent ? refreshUnreadNotification(state) : .none

            case .path, .coverPath, .detailCover:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$detailCover, action: \.detailCover) {
            CommunityDetailFeature()
        }
        .forEach(\.path, action: \.path)
        .forEach(\.coverPath, action: \.coverPath)
        // 상세가 열리고 닫히는 것(ifLet · forEach가 바꿈)까지 보려고 맨 바깥에 둔다.
        .onChange(of: \.isWatchingConnection) { _, isWatching in
            Reduce { _, _ in
                WebConnectionRetry.watchEffect(
                    isWatching: isWatching,
                    id: CancelID.connectionWatch,
                    networkPathClient: networkPathClient,
                    clock: clock,
                    restored: .internal(.connectionRestored)
                )
            }
        }
    }

    // MARK: - 헤더 표시(새 알림 점)

    /// 진입·탭 복귀·포그라운드·로그인 때 헤더의 새 알림 점을 다시 조회한다.
    /// 헤더의 내 사진 버튼은 MY 탭과 입구가 겹쳐 뺐다 — 내 프로필은 아래 MY 탭 하나로 들어간다.
    private func refreshHeaderState(_ state: State) -> Effect<Action> {
        refreshUnreadNotification(state)
    }

    /// 안 읽은 알림 여부를 다시 조회한다. 비로그인이면 알림함이 없으므로 조회하지 않는다.
    private func refreshUnreadNotification(_ state: State) -> Effect<Action> {
        guard state.isNotificationButtonVisible else { return .none }
        return .run { [noticeClient] send in
            await send(.internal(.unreadNotificationResponse(
                await TaskResult { try await noticeClient.hasUnread() }
            )))
        }
        .cancellable(id: CancelID.unreadNotification, cancelInFlight: true)
    }

    /// 커뮤니티 활동 웹 라우트(`/community/me`). 알림함과 같이 숫자 id가 아니라 게시글 상세로 오인되지 않는다.
    private static let myActivityPath = "/\(DeepLinkParser.communitySegment)/me"

    /// 알림함과 같은 이유로 리스트 웹뷰와 같은 origin에 커뮤니티 활동 경로를 붙인다.
    /// MY 탭의 '커뮤니티 활동' 줄(#44)이 이 origin으로 열도록 AppTabFeature가 쓴다.
    static func myActivityURL(base: URL) -> URL? {
        URL(string: myActivityPath, relativeTo: base)?.absoluteURL
    }

    /// 차단한 회원 웹 라우트(`/community/blocked-users`). 설정의 '차단한 회원' 줄(#56)이 리스트 웹뷰와 같은 origin으로 연다.
    private static let blockedUsersPath = "/\(DeepLinkParser.communitySegment)/blocked-users"

    static func blockedUsersURL(base: URL) -> URL? {
        URL(string: blockedUsersPath, relativeTo: base)?.absoluteURL
    }

    /// 글 검색 웹 라우트(`/community/search`, #435). 검색어 없이 열면 웹이 '최근 검색'을 보여 준다.
    private static let searchPath = "/\(DeepLinkParser.communitySegment)/search"

    static func searchURL(base: URL) -> URL? {
        URL(string: searchPath, relativeTo: base)?.absoluteURL
    }

    /// 닫힐 때 새 알림 점을 다시 읽을 화면 — 알림함과 글 · 밸런스 게임 상세(열면 그 글 알림이 읽음 처리된다, #401).
    private static func refreshesUnreadOnClose(_ element: Path.State?) -> Bool {
        guard case let .detail(detail)? = element else { return false }
        return NotificationInbox.isInbox(detail.url) || DeepLinkParser.isContentDetail(detail.url)
    }

    // MARK: - Subview 라우팅 헬퍼

    /// 상세 서브뷰의 위임을 받아 스택/모달을 갱신하거나, 인증류는 부모(AppTab)로 다시 위임한다.
    private static func handleDetailDelegate(
        _ delegate: CommunityDetailFeature.Action.DelegateAction,
        from container: SubviewContainer,
        into state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case let .openSubviewRequested(payload):
            // 이미 서브뷰 안이므로 같은 컨테이너에 push로 쌓는다(모달 위 모달 중첩 방지).
            return openSubview(payload, from: container, into: &state)
        case let .loginPromptRequested(reason):
            return .send(.delegate(.loginPromptRequested(reason: reason)))
        case let .loginModalRequested(reason):
            return .send(.delegate(.loginModalRequested(reason: reason)))
        case .logoutRequested:
            return .send(.delegate(.logoutRequested))
        case .tokenRefreshRequested:
            return .send(.delegate(.tokenRefreshRequested))
        case .myTabRequested:
            return .send(.delegate(.myProfileRequested))
        case let .userProfileRequested(userId):
            // 모달 안이면 openUserProfile이 모달 스택에 쌓는다
            return .send(.openUserProfile(userId: userId))
        case let .competitionAlertsChecked(check):
            return .send(.delegate(.competitionAlertsChecked(check)))
        case let .homeFeedRequested(filter):
            return .send(.delegate(.homeFeedRequested(filter)))
        case let .competitionRecordRequested(payload):
            return .send(.delegate(.competitionRecordRequested(payload)))
        case .competitionHeaderTintChanged:
            // 대회 탭 목록만 알리는 신호라 쌓인 상세는 이미 무시했다.
            return .none
        case .contentCreated:
            return .send(.delegate(.contentCreated))
        }
    }

    /// MY 화면의 '커뮤니티 활동'(내 글·댓글 웹)을 그 MY가 놓인 스택에 쌓는다(#197).
    private static func pushMyActivity(from container: SubviewContainer, into state: inout State) -> Effect<Action> {
        guard let base = state.url, let url = myActivityURL(base: base) else { return .none }
        let detail = subview(url: url, accessToken: state.accessToken)
        switch container {
        case .push: state.path.append(.detail(detail))
        case .modal: state.coverPath.append(.detail(detail))
        }
        return .none
    }

    /// 커뮤니티에서 MY 화면을 연다(#197). 상세 모달이 떠 있으면 모달 안 스택에 쌓는다.
    /// 남의 프로필처럼 누른 화면 위에 쌓아, 뒤로가기를 누르면 누른 그 화면(글 상세 등)으로 돌아간다.
    /// 연타·중복 전달로 MY가 겹쳐 쌓이지 않게 맨 위가 이미 MY면 그대로 둔다.
    public static func pushMyProfile(_ profile: MyProfileFeature.State, into state: inout State) {
        let top = state.detailCover != nil ? state.coverPath.last : state.path.last
        if case .myProfile? = top { return }
        if state.detailCover != nil {
            state.coverPath.append(.myProfile(profile))
        } else {
            state.path.append(.myProfile(profile))
        }
    }

    /// 홈에서 연 대회 상세 위에 기록 추가를 쌓는다(#304). 상세 모달이 떠 있으면 그 안 스택에 쌓는다 —
    /// 버튼을 누를 수 있는 상세는 맨 위 화면뿐이라, 모달이 있으면 그 상세는 모달 안에 있다.
    /// 연타·중복 전달로 입력 화면이 겹쳐 쌓이지 않게 맨 위가 이미 기록 추가면 그대로 둔다(대회 탭과 같은 방식).
    public static func pushCompetitionRecord(_ record: CompetitionInfoFeature.State, into state: inout State) {
        let top = state.detailCover != nil ? state.coverPath.last : state.path.last
        if case .competitionInfo? = top { return }
        if state.detailCover != nil {
            state.coverPath.append(.competitionInfo(record))
        } else {
            state.path.append(.competitionInfo(record))
        }
    }

    /// 홈에 쌓인 화면(푸시 스택·상세 모달·모달 안 스택)을 모두 닫고 피드를 맨 위로 올려, 피드 첫 화면이 바로 보이게 한다(#250, #304).
    /// 맨 위까지 올리는 이유(#386): 부르는 곳(대회 '커뮤니티에서 더 보기', 웹의 '오늘의 게임 하러 가기')은 피드 맨 위의
    /// 오늘의 밸런스 게임·새 글을 보러 가는 것인데, 피드를 내려 둔 채였으면 닫기만 해서는 그 자리가 보이지 않는다.
    public static func closeToFeed(into state: inout State) {
        state.path.removeAll()
        state.detailCover = nil
        state.coverPath.removeAll()
        state.scrollToTopToken = UUID()
    }

    /// 대회 이야기 '모두 보기'(#437): 홈 피드를 `/?competitionId=<번호>`로 다시 불러온다. 웹이 '대회' 탭을 고르고
    /// 그 대회 글만 보여 준다(jiu-jitsu-frontend#598). 글 상세의 카테고리 이름(#480)은 `/?categoryId=<번호>`로 그 카테고리 탭을 연다.
    /// 다른 탭을 보고 있었거나 같은 주소여도 다시 불러와 맞춘다 — 웹 안에서 탭을 바꾸면 앱의 `state.url`은 그대로라
    /// 지금 보는 탭을 앱이 알 수 없다.
    /// 필터 없이 홈으로 오면(오늘의 게임·커뮤니티에서 더 보기 등) 앞서 건 대회 필터만 풀고, 필터가 없으면 보던 피드를 그대로 둔다.
    public static func reloadFeed(filter: HomeFeedFilter?, into state: inout State) {
        guard let base = makeCommunityURL() else { return }
        let target: URL?
        if let filter {
            let query = switch filter {
            case let .competition(id): "\(competitionIdQueryName)=\(id)"
            case let .category(id): "categoryId=\(id)"
            }
            target = URL(string: "/?\(query)", relativeTo: base)?.absoluteURL
        } else if let current = state.url, hasCompetitionFilter(current) {
            target = base
        } else {
            return
        }
        // 같은 주소를 이미 불러오는 중이면(같은 신호가 잇달아 옴) 다시 부르지 않는다 — 진행 중인 로드를 끊으면 오류 화면이 뜬다.
        if state.isLoading, state.url == target { return }
        reloadCommunity(&state, url: target)
    }

    private static let competitionIdQueryName = "competitionId"

    private static func hasCompetitionFilter(_ url: URL) -> Bool {
        URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?.contains { $0.name == competitionIdQueryName } ?? false
    }

    /// 로그아웃·탈퇴 때 이전 계정으로 연 MY 화면(#197)과 대회 기록 추가(#304)를 닫는다. 그 위에 쌓인 화면도 함께 닫는다.
    public static func closeAccountScreens(into state: inout State) {
        func isAccountScreen(_ element: Path.State) -> Bool {
            switch element {
            case .myProfile, .competitionInfo: true
            case .detail, .userProfile: false
            }
        }
        if let index = state.path.firstIndex(where: isAccountScreen) {
            state.path.removeSubrange(index...)
        }
        if let index = state.coverPath.firstIndex(where: isAccountScreen) {
            state.coverPath.removeSubrange(index...)
        }
    }

    /// 세션 변화(토큰 갱신/로그인 취소/로그아웃/만료)를 열려 있는 모든 상세 서브뷰(푸시 스택·모달 스택·모달 루트)에
    /// 전파한다. 상세는 리스트와 별개 WKWebView라 각자 토큰을 동기화해야 한다.
    private static func broadcastToDetails(_ update: CommunityDetailFeature.SessionUpdate, into state: inout State) {
        for id in state.path.ids {
            if case .detail(let existing) = state.path[id: id] {
                var detail = existing
                CommunityDetailFeature.apply(update, into: &detail)
                state.path[id: id] = .detail(detail)
            }
        }
        for id in state.coverPath.ids {
            if case .detail(let existing) = state.coverPath[id: id] {
                var detail = existing
                CommunityDetailFeature.apply(update, into: &detail)
                state.coverPath[id: id] = .detail(detail)
            }
        }
        if var cover = state.detailCover {
            CommunityDetailFeature.apply(update, into: &cover)
            state.detailCover = cover
        }
    }

    /// OPEN_SUBVIEW를 동일 origin 검증 후 push/modal로 표시한다.
    /// - 리스트(.push 컨테이너)에서의 modal 요청만 모달로 띄우고,
    ///   서브뷰 안에서의 중첩 요청은 현재 컨테이너에 push로 강등한다(모달 중첩 방지).
    private static func openSubview(
        _ payload: OpenSubviewPayload,
        from container: SubviewContainer,
        into state: inout State
    ) -> Effect<Action> {
        guard
            let base = state.url,
            let target = URL(string: payload.url),
            WebOrigin.isSameOrigin(target, as: base)
        else {
            Log.trace("OPEN_SUBVIEW 무시(잘못된 URL/교차 출처): \(payload.url)", category: .network, level: .error)
            return .none
        }

        let detail = subview(
            url: target,
            title: payload.title,
            accessToken: state.accessToken
        )

        switch container {
        case .push:
            switch payload.presentation {
            case .push:
                state.path.append(.detail(detail))
            case .modal:
                // 새 모달을 띄우기 전, 이전 모달의 잔여 내부 스택을 비워 신선한 상태로 연다.
                state.coverPath = .init()
                state.detailCover = detail
            }
        case .modal:
            if payload.presentation == .modal {
                Log.trace("중첩 OPEN_SUBVIEW presentation=modal → 모달 내부 push로 강등", category: .network, level: .info)
            }
            state.coverPath.append(.detail(detail))
        }
        return .none
    }

    /// 딥링크로 들어온 상세(게시글·밸런스 게임)를 현재 최상단 컨테이너에 연다.
    /// 어느 상세든 URL을 그대로 로드하는 같은 웹뷰라 `DeepLink` 케이스를 구분하지 않는다.
    ///
    /// 모달이 떠 있으면 모달을 닫지 않고 그 내부 스택에 쌓는다. dismiss와 push가 같은 틱에
    /// 겹치면 전환이 튀기 때문으로, 중첩 OPEN_SUBVIEW를 push로 강등하는 것과 같은 이유다.
    private static func openDeepLink(_ link: DeepLink, into state: inout State) -> Effect<Action> {
        let container: SubviewContainer = state.detailCover != nil ? .modal : .push
        // 같은 글이 이미 최상단이면 새로 쌓지 않는다. 링크 재탭이나 중복 전달로 상세가 겹쳐 쌓이는 것을 막는다.
        // 대신 보고 있는 글의 푸시(새 댓글 등)면 다시 불러와 새 내용을 보인다(#383).
        // 아직 첫 로딩 중이면 같은 링크가 두 경로로 잇달아 들어온 중복 전달이라 그대로 둔다.
        // 댓글 · 답글을 쓰는 중(키보드 ↑)이면 답글 대상이 사라지므로 다시 불러오지 않는다.
        // 댓글 푸시(`?commentId=`)면 그 주소로 불러와 웹이 그 댓글을 맨 위에 보이게 하고(#436),
        // 아니면 앞서 붙은 댓글 번호를 빼고 불러와 예전 댓글이 다시 맨 위에 묶이지 않게 한다.
        // 로딩 중에는 다른 댓글이어도 그대로 둔다 — 진행 중인 로드를 끊으면 웹뷰가 취소(-999)를 실패로 받아 오류 화면이 뜬다.
        let commentURL = DeepLinkParser.hasCommentId(link.url) ? link.url : nil
        var didReload = false
        if updateTopDetail(url: link.url, in: &state, container: container, { top in
            guard !top.isLoading, !top.isKeyboardVisible else { return }
            CommunityDetailFeature.reload(&top, url: commentURL ?? DeepLinkParser.removingCommentId(from: top.url))
            didReload = true
        }) {
            Log.trace(
                "딥링크: 이미 최상단인 글 — \(didReload ? "다시 불러옴" : "로딩 중 · 입력 중이라 그대로 둠"): \(link.url.absoluteString)",
                category: .view,
                level: .info
            )
            return .none
        }

        var detail = subview(url: link.url, accessToken: state.accessToken)
        detail.entryOrigin?.via = .deeplink
        switch container {
        case .push:
            state.path.append(.detail(detail))
        case .modal:
            state.coverPath.append(.detail(detail))
        }
        return .none
    }

    /// 해당 컨테이너의 최상단에 같은 글(호스트 · 경로, 쿼리 무시 — `?from=` · utm)의 상세가 떠 있으면 그 상태를 고치고 true를 돌려준다.
    private static func updateTopDetail(
        url: URL,
        in state: inout State,
        container: SubviewContainer,
        _ update: (inout CommunityDetailFeature.State) -> Void
    ) -> Bool {
        switch container {
        case .push:
            guard let id = state.path.ids.last, case var .detail(top)? = state.path[id: id], WebOrigin.isSamePage(top.url, url) else { return false }
            update(&top)
            state.path[id: id] = .detail(top)
            return true
        case .modal:
            if let id = state.coverPath.ids.last {
                guard case var .detail(top)? = state.coverPath[id: id], WebOrigin.isSamePage(top.url, url) else { return false }
                update(&top)
                state.coverPath[id: id] = .detail(top)
                return true
            }
            guard var top = state.detailCover, WebOrigin.isSamePage(top.url, url) else { return false }
            update(&top)
            state.detailCover = top
            return true
        }
    }

    /// 확인 알럿 표시 요청 처리. 이미 다이얼로그가 떠 있으면 새 요청은 즉시 dismiss로 회신한다
    /// (동시 표시 없이 하나만 — 계약: 큐잉하지 않음).
    private static func presentConfirmDialog(_ payload: ConfirmDialogPayload, into state: inout State) -> Effect<Action> {
        guard state.pendingConfirmDialog == nil, state.pendingSelectSheet == nil else {
            enqueue(.confirmDialogResult(requestId: payload.requestId, outcome: .dismiss), into: &state)
            return .none
        }
        state.pendingConfirmDialog = payload
        return .none
    }

    /// 선택 시트 표시 요청 처리(동시 표시 방지는 presentConfirmDialog와 동일).
    private static func presentSelectSheet(_ payload: SelectSheetPayload, into state: inout State) -> Effect<Action> {
        guard state.pendingConfirmDialog == nil, state.pendingSelectSheet == nil else {
            enqueue(.selectSheetResult(requestId: payload.requestId, outcome: .dismiss), into: &state)
            return .none
        }
        state.pendingSelectSheet = payload
        return .none
    }

    /// 기기 알림 상태를 본다. 아직 묻지 않았으면 시스템 권한 창의 답까지 기다린다(#395).
    private func checkCompetitionAlerts(competitionId: Int?, requestId: String?) -> Effect<Action> {
        Log.trace("관심 대회 알림 켬: competitionId=\(competitionId.map(String.init) ?? "-")", category: .view, level: .info)
        return .run { send in
            let check = await DeviceNotificationCheck.current(permission: notificationPermissionClient, firebase: firebaseClient)
            await send(.internal(.competitionAlertsChecked(requestId: requestId, check)))
        }
    }

    /// 글 · 밸런스 게임 종을 켰을 때 기기 알림 상태를 본다 — 대회 쪽과 같다(#466).
    private func checkContentAlerts(contentId: Int?, requestId: String) -> Effect<Action> {
        Log.trace("글 알림 켬: contentId=\(contentId.map(String.init) ?? "-")", category: .view, level: .info)
        return .run { send in
            let check = await DeviceNotificationCheck.current(permission: notificationPermissionClient, firebase: firebaseClient)
            await send(.internal(.contentAlertsChecked(requestId: requestId, check)))
        }
    }

    /// 아웃바운드 메시지를 식별자와 함께 대기열에 추가한다.
    private static func enqueue(_ message: WebBridgeOutboundMessage, into state: inout State) {
        state.outbox.append(WebBridgeOutboundEnvelope(id: UUID(), message: message))
    }

    /// AUTH_LOGIN_SUCCESS를 큐에 넣는다.
    private static func enqueueLoginSuccess(accessToken: String, into state: inout State) {
        enqueue(.authLoginSuccess(accessToken: accessToken), into: &state)
    }

    /// WEBVIEW_READY 핸드셰이크에서 초기 로그인 상태를 동기화한다.
    ///
    /// 만료된 토큰은 절대 주입하지 않는다. 웹은 이 재주입과 AUTH_TOKEN_REFRESH_REQUEST의 응답을
    /// 같은 메시지(AUTH_LOGIN_SUCCESS)로 받아 구분할 수 없어, 만료 토큰을 주입하면 "갱신됐다"고
    /// 판단하고 같은 토큰으로 재조회하다 403(A0003)으로 복구에 실패한다. (#26)
    /// 만료 상태면 주입 대신 네이티브 갱신을 먼저 태우고, 그 결과를 AUTH_LOGIN_SUCCESS(새 토큰)
    /// 또는 AUTH_SESSION_EXPIRED로 회신한다. 게스트면 AUTH_LOGOUT을 보낸다.
    private static func syncSessionOnReady(into state: inout State) -> Effect<Action> {
        guard let accessToken = state.accessToken else {
            // 게스트로 바뀔 때 보낸 AUTH_LOGOUT을 놓친 웹(로딩 중 · 오류 · 다시 뜬 웹)도 비로그인으로 맞춘다(#372).
            // 웹은 이미 비로그인이던 화면에 온 로그아웃은 다시 읽지 않는다.
            WebBridge.logEvent("WEBVIEW_READY: 게스트 → AUTH_LOGOUT으로 남은 세션 정리", source: .list)
            enqueue(.authLogout, into: &state)
            return .none
        }
        guard !JWTDecoder.isExpired(accessToken) else {
            WebBridge.logEvent("WEBVIEW_READY: accessToken 만료 → 재주입 보류, 네이티브 갱신 요청", source: .list)
            return .send(.delegate(.tokenRefreshRequested))
        }
        enqueueLoginSuccess(accessToken: accessToken, into: &state)
        return .none
    }

    /// Info.plist WEB_URL — 오버라이드가 없을 때 로드되는 기본 도메인.
    /// 테스트용 도메인 변경 다이얼로그가 "기본값"을 그대로 보여주기 위해 View에도 노출한다.
    static var defaultWebURLString: String {
        WebEnvironment.webURLString
    }

    /// 홈 피드 웹 주소. 스플래시가 홈 피드를 미리 불러 둘 때(#270)도 같은 주소를 써야 홈 웹뷰가 이어받는다.
    static func makeCommunityURL() -> URL? {
#if DEBUG || BETA
        // 테스트용 도메인 오버라이드가 설정돼 있으면 WEB_URL보다 우선 사용한다.
        if let override = WebEnvironment.debugOverrideURL() {
            Log.trace("커뮤니티 웹뷰 도메인 오버라이드 사용: \(override.absoluteString)", category: .system, level: .info)
            return override
        }
#endif
        let urlString = defaultWebURLString
        guard
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            Log.trace("WEB_URL is not set in Info.plist", category: .system, level: .error)
            return nil
        }
        return url
    }

    /// 같은 주소로 다시 불러온다 — 재시도 버튼, 연결이 돌아옴(#396).
    private static func retryLoad(_ state: inout State) {
        // URL이 아직도 nil이면 WKWebView가 생성되지 않으므로 재시도해도 콜백이 오지 않는다.
        // 다시 만들어보고, 그래도 실패하면 에러 상태를 유지한다.
        if state.url == nil {
            state.url = Self.makeCommunityURL()
        }
        guard state.url != nil else {
            state.hasError = true
            state.isLoading = false
            return
        }
        state.hasError = false
        state.isLoading = true
        state.loadToken = UUID()
    }

    // MARK: - 테스트용 도메인 오버라이드 (UserDefaults)

    /// 입력 주소로 URL을 다시 만들고 강제 reload되도록 상태를 초기화한다.
    private static func reloadCommunity(_ state: inout State, url: URL? = makeCommunityURL()) {
        state.url = url
        // URL이 동일해도 View가 reload를 인지하도록 토큰을 갱신한다.
        state.loadToken = UUID()
        // 도메인이 바뀌면 이전 웹 컨텍스트의 전달 대기 메시지는 의미가 없다.
        state.outbox.removeAll()
        // 새 웹이 다시 알려 줄 때까지 흰 머리줄 — 주소가 없어 오류 화면만 남을 때 지난 진한 색이 남지 않게.
        state.headerTint = nil
        state.connectionRetry.reset()
        if url == nil {
            state.isLoading = false
            state.hasError = true
        } else {
            state.isLoading = true
            state.hasError = false
        }
    }

    /// 사용자가 입력한 문자열을 로드 가능한 URL 문자열로 정규화한다.
    /// 스킴을 생략하면(`192.168.0.10:3000`) http로 처리해 ip만 입력해도 바로 열리게 한다.
    private static func normalizedURLString(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.contains("://") ? trimmed : "http://\(trimmed)"
    }

    private static func setDebugOverrideURLString(_ value: String?) {
        let defaults = UserDefaults.standard
        if let value, !value.isEmpty {
            defaults.set(value, forKey: WebEnvironment.debugURLOverrideKey)
        } else {
            defaults.removeObject(forKey: WebEnvironment.debugURLOverrideKey)
        }
    }

}

extension CommunityFeature.Path.State: Sendable, Equatable {}
extension CommunityFeature.Path.Action: Sendable {}
