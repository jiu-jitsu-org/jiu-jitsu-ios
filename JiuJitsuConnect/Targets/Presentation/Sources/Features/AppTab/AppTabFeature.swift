//
//  AppTabFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import Domain
import CoreKit

@Reducer
public struct AppTabFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        // 401 인터셉터가 방송하는 세션 이벤트 구독. AppTab 생명주기 동안만 유지한다.
        case sessionObserver
        // 관심 대회 알림 켜기(#257) — 권한 창을 기다리는 동안 로그아웃되면 이전 계정으로 FCM을 등록하지 않게 끊는다.
        case competitionAlerts
    }

    // 세 번째 탭은 설정 대신 대회(#240). 설정은 MY 오른쪽 위로 옮겼다(#241).
    public enum Tab: String, CaseIterable, Equatable, Sendable {
        case home = "홈"
        case competition = "대회"
        case myPage = "MY"
    }

    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .home
        // 화면에 띄워 둔 탭. 앱을 켤 때 안 보이는 탭(대회 웹·MY)까지 한꺼번에 띄우면 그 요청이 홈 피드와 같은 순간에
        // 서버로 몰리므로, 홈 피드가 보인 뒤나 그 탭에 처음 들어갈 때 띄운다(#271). 한 번 띄운 탭은 내리지 않는다.
        var mountedTabs: Set<Tab> = [.home]
        // 홈 위에 인사 장면이 떠 있는지. 떠 있는 동안은 안 보이는 탭을 띄우지 않는다 —
        // 웹뷰를 만드는 비용이 인사 움직임을 끊지 않게 한다(#207).
        var isGreetingShowing: Bool

        // 각 탭의 독립적인 State
        var home: CommunityFeature.State
        var competition: CompetitionTabFeature.State
        var myPage: MyProfileFeature.State

        // 로그인 모달
        @Presents var loginCover: LoginFeature.State?
        // 게스트가 로그인이 필요한 행위(커뮤니티 글쓰기·대회 관심 등)를 할 때 노출되는 공통 AppAlert 표시 여부
        var isLoginPromptPresented: Bool = false
        // 관심 대회 알림을 켰는데 기기 알림이 꺼져 있을 때 설정 앱으로 안내하는 AppAlert 표시 여부(#257)
        var isDeviceNotificationAlertPresented: Bool = false
        // 로그인 모달이 어느 탭 웹뷰의 행위(글쓰기·관심 등록 등)에서 트리거됐는지(홈·대회).
        // 값이 있으면 로그인 성공 시 탭 전환 없이 그 탭에 머물러 행위를 복귀시키고,
        // 취소 시 그 웹에 AUTH_LOGIN_CANCELLED를 보내 대기 중 행위를 폐기시킨다.
        var pendingWebLoginTab: Tab?
        // 비로그인으로 누른 대회 상세의 '내 기록에 남기기'(#250). 로그인하면 이 대회로 기록 추가를 이어서 연다.
        var pendingCompetitionRecord: OpenCompetitionRecordPayload?
        // 세션 이벤트 구독을 onAppear 중복 호출에도 한 번만 시작하기 위한 가드.
        var didStartSessionObserver: Bool = false
        // 웹뷰 위임 토큰 갱신이 진행 중인지. 리스트·상세 여러 웹뷰가 동시에 만료를 감지해도
        // 갱신은 한 번만 태우고 결과를 모두에게 전파한다. (refreshToken은 서버에서 1회용으로 회전)
        var isRefreshingWebToken: Bool = false
        // 로그아웃 정리(서버 요청·FCM 폐기)가 끝나 게스트로 바뀌기 전까지 다시 들어온 로그아웃을 막는다.
        var isLoggingOut: Bool = false

        var authInfo: AuthInfo

        public init(authInfo: AuthInfo, isGreetingShowing: Bool = false) {
            self.authInfo = authInfo
            self.isGreetingShowing = isGreetingShowing
            // 이미 로그인 상태로 진입하면 WEBVIEW_READY 핸드셰이크 때 토큰을 주입하도록 전달.
            let home = CommunityFeature.State(accessToken: authInfo.accessToken)
            self.home = home
            // 대회 웹은 커뮤니티 웹과 같은 origin(테스트용 도메인 오버라이드 포함)으로 연다.
            self.competition = CompetitionTabFeature.State(base: home.url, accessToken: authInfo.accessToken)
            self.myPage = MyProfileFeature.State(authInfo: authInfo)
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        // 자식 Feature 액션 연결
        case home(CommunityFeature.Action)
        case competition(CompetitionTabFeature.Action)
        case myPage(MyProfileFeature.Action)

        case loginCover(PresentationAction<LoginFeature.Action>)

        // 부모(AppFeature)가 파싱해 넘긴 유니버설 링크.
        case deepLink(DeepLink)
        // 부모(AppFeature)가 홈을 덮던 인사 장면을 걷었다(끝남·건너뜀·딥링크로 접힘).
        case greetingFinished

        @CasePathable
        public enum ViewAction: Sendable {
            case onAppear
            case sceneBecameActive
            case tabSelected(Tab)
            case loginPromptLoginTapped
            case loginPromptDismissed
            // 로그인 안내 알럿의 [취소] 버튼 전용. (loginPromptDismissed는 알럿이 닫힐 때마다
            // 바인딩에 의해 함께 호출되므로, 취소 부수효과는 이 액션에만 둔다.)
            case loginPromptCancelTapped
            // 기기 알림 꺼짐 안내(#257)의 [설정으로 가기]·닫힘([나중에] 포함)
            case deviceNotificationAlertSettingsTapped
            case deviceNotificationAlertDismissed
        }

        public enum InternalAction: Sendable {
            case showLoginPromptAlert
            case showLoginModal
            case showDeviceNotificationAlert
            // 관심 대회 알림 켜기 중 권한 창에서 허용함(#257). 그 사이 로그아웃했을 수 있어 지금 상태를 보고 FCM을 등록한다.
            case competitionAlertsPermissionGranted
            // 웹 주도 로그아웃 요청(AUTH_LOGOUT_REQUEST) 처리.
            case performWebLogout
            case webLogoutCompleted
            // 401 인터셉터가 방송한 세션 이벤트 수신.
            case sessionEvent(AuthSessionEvent)
            // 웹뷰 위임 토큰 갱신 성공 → 새 토큰을 웹에 주입.
            case tokenRefreshSucceeded(accessToken: String)
            // 웹뷰 위임 토큰 갱신이 네트워크·서버 오류로 일시 실패 → 세션은 유지한다.
            case tokenRefreshFailed
            // 토큰 갱신 불가(세션 만료) → 게스트로 전환 + 웹 세션 정리.
            case handleSessionExpired
            // 대회 탭에서 연 기록 추가의 저장 결과(#250). id는 결과를 돌려줄 대회 탭 스택의 입력 화면.
            case competitionRecordSaved(id: StackElementID, competition: Competition, TaskResult<CommunityProfile>)
        }
    }

    // MARK: - Dependencies
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.authSessionEventClient) var authSessionEventClient
    @Dependency(\.notificationPermissionClient) var notificationPermissionClient
    @Dependency(\.communityClient) var communityClient
    @Dependency(\.competitionAlertSettingClient) var competitionAlertSettingClient
    @Dependency(\.openURL) var openURL

    public var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            CommunityFeature()
        }
        Scope(state: \.competition, action: \.competition) {
            CompetitionTabFeature()
        }
        Scope(state: \.myPage, action: \.myPage) {
            MyProfileFeature()
        }

        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 401 인터셉터의 세션 이벤트(토큰 자동 갱신/세션 만료)를 구독한다.
                guard !state.didStartSessionObserver else { return .none }
                state.didStartSessionObserver = true
                return .run { send in
                    for await event in authSessionEventClient.events() {
                        await send(.internal(.sessionEvent(event)))
                    }
                }
                .cancellable(id: CancelID.sessionObserver, cancelInFlight: false)

            case let .view(.tabSelected(tab)):
                // 이미 홈인데 홈 아이콘을 다시 누르면 피드를 맨 위로 올린다(#229).
                if tab == .home, state.selectedTab == .home {
                    return .send(.home(.view(.tabReselected)))
                }
                // 다른 탭에서 커뮤니티로 돌아오면 새 알림 점을 갱신한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음).
                if tab == .home, state.selectedTab != .home {
                    state.selectedTab = tab
                    return .send(.home(.view(.tabEntered)))
                }
                // 이미 대회인데 대회 아이콘을 다시 누르면 목록을 맨 위로 올린다(#240, 홈과 같은 동작).
                if tab == .competition, state.selectedTab == .competition {
                    return .send(.competition(.view(.tabReselected)))
                }
                // 대회 탭 머리줄의 종도 홈의 새 알림 점을 그리므로, 들어올 때 홈에 다시 조회시킨다(#258).
                let refreshUnread: Effect<Action> = tab == .competition && state.selectedTab != .competition
                    ? .send(.home(.unreadNotificationRefreshRequested))
                    : .none
                // 처음 만들 때 웹 주소가 없었으면(커뮤니티 주소 미정) 들어올 때 다시 만든다 — 홈이 다시 시도해 주소를 얻었을 수 있다.
                if tab == .competition, state.competition.web == nil {
                    // 토큰은 갱신이 반영된 커뮤니티 쪽 값을 쓴다(authInfo는 갱신 때 바뀌지 않는다).
                    state.competition = CompetitionTabFeature.State(
                        base: state.home.url,
                        accessToken: state.home.accessToken ?? state.authInfo.accessToken
                    )
                }
                // 비로그인도 MY를 연다 — 로그인 안내와 설정 입구가 있다(#242).
                // 다른 탭에서 MY로 돌아오면 프로필을 재조회한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음, #69).
                let isEnteringMyPage = tab == .myPage && state.selectedTab != .myPage
                state.selectedTab = tab
                if isEnteringMyPage, !state.authInfo.isGuest {
                    return .send(.myPage(.view(.tabEntered)))
                }
                return refreshUnread

            case .view(.sceneBecameActive):
                // MY 탭을 보고 있을 때만 포그라운드 복귀 재조회 (#69)
                guard state.selectedTab == .myPage, !state.authInfo.isGuest else { return .none }
                return .send(.myPage(.view(.sceneBecameActive)))

            // MARK: - 설정 (MY 스택에서 연다, #241)

            case .myPage(.delegate(.settings(.loginRequested))),
                 .myPage(.delegate(.loginRequested)):
                return .send(.internal(.showLoginModal))

            case .myPage(.delegate(.settings(.didWithdrawSuccessfully))):
                Self.resetToGuest(&state)
                return .merge(
                    Self.broadcastLoggedOut(),
                    .cancel(id: CancelID.competitionAlerts),
                    // 로컬 세션 정리를 끝낸 뒤 로그인 모달을 띄운다. 먼저 띄우면 새로 로그인한 토큰을
                    // 뒤늦은 signOut이 지우거나, 새 로그인이 폐기 직전의 FCM 토큰을 등록할 수 있다.
                    .run { send in
                        await authClient.signOut()
                        await Self.discardDeviceFCMToken(firebaseClient, context: "withdrawal")
                        await send(.internal(.showLoginModal))
                    }
                )

            // MARK: - Community Web Bridge Delegate
            case let .home(.delegate(.loginPromptRequested(reason))):
                // 커뮤니티 웹뷰의 비로그인 행위 → "로그인이 필요해요" 안내 알럿(소프트 유도).
                state.pendingWebLoginTab = .home
                Log.trace("커뮤니티 로그인 알럿 요청: reason=\(reason ?? "-")", category: .view, level: .info)
                return .send(.internal(.showLoginPromptAlert))

            case let .home(.delegate(.loginModalRequested(reason))):
                // 커뮤니티 웹뷰의 비로그인 행위 → 로그인 모달 즉시 노출(다이렉트).
                state.pendingWebLoginTab = .home
                Log.trace("커뮤니티 로그인 모달 요청: reason=\(reason ?? "-")", category: .view, level: .info)
                return .send(.internal(.showLoginModal))

            // 커뮤니티의 내 사진 버튼(#128)·피드·글 상세·댓글에서 내 이름 탭(#116).
            // 남의 사진을 누를 때처럼 MY 화면을 커뮤니티 스택에 쌓아 뒤로가기로 돌아오게 한다(#197).
            // 탭의 MY가 불러 둔 프로필을 넘겨 바로 그린다. 게스트는 커뮤니티 행위와 같이 로그인 안내를 띄운다.
            case .home(.delegate(.myProfileRequested)):
                guard !state.authInfo.isGuest else {
                    return .send(.internal(.showLoginPromptAlert))
                }
                CommunityFeature.pushMyProfile(.pushed(from: state.myPage), into: &state.home)
                return .none

            // MY 탭 웹 서브뷰(커뮤니티 활동·차단한 회원)·대회 탭 웹에서 내 이름 탭. 탭바에서 MY를 누른 것과 같은 경로라 프로필 재조회도 그대로 따른다.
            // 내 사진은 내 프로필을 뜻하므로, MY에 열어 둔 하위 화면(커뮤니티 활동 등)은 닫고 프로필 첫 화면으로 보낸다.
            case .myPage(.delegate(.webSubview(.myTabRequested))),
                 .competition(.delegate(.myTabRequested)):
                if !state.authInfo.isGuest {
                    state.myPage.path.removeAll()
                    state.home.detailCover = nil
                    state.home.coverPath.removeAll()
                }
                return .send(.view(.tabSelected(.myPage)))

            // 설정의 로그아웃 확인(#241)도 같은 경로 — 설정은 MY 스택의 한 화면이라 닫히면 거기서 돌던 요청이 취소된다.
            case .home(.delegate(.logoutRequested)),
                 .myPage(.delegate(.webSubview(.logoutRequested))),
                 .myPage(.delegate(.settings(.logoutConfirmed))),
                 .competition(.delegate(.webSubview(.logoutRequested))):
                return .send(.internal(.performWebLogout))

            case .home(.delegate(.tokenRefreshRequested)),
                 .myPage(.delegate(.webSubview(.tokenRefreshRequested))),
                 .competition(.delegate(.webSubview(.tokenRefreshRequested))):
                // 하이브리드 토큰 소유권은 네이티브 — 웹뷰 만료 시 네이티브 refresh로 갱신해 웹에 돌려준다.
                // 갱신 결과는 열려 있는 모든 웹뷰에 전파되므로, 진행 중이면 그 응답을 함께 기다리면 된다.
                guard !state.isRefreshingWebToken else { return .none }
                state.isRefreshingWebToken = true
                return .run { send in
                    do {
                        let accessToken = try await authClient.refreshSession()
                        await send(.internal(.tokenRefreshSucceeded(accessToken: accessToken)))
                    } catch DomainError.apiError(code: .invalidRefreshToken, message: _) {
                        // refresh 토큰까지 무효일 때만 세션을 끝낸다(네트워크 레이어가 세션 만료를 이 코드로 매핑).
                        Log.trace("웹뷰 위임 토큰 갱신 실패 → 세션 만료 처리", category: .network, level: .error)
                        await send(.internal(.handleSessionExpired))
                    } catch {
                        Log.trace("웹뷰 위임 토큰 갱신 일시 실패 → 세션 유지: \(error)", category: .network, level: .error)
                        await send(.internal(.tokenRefreshFailed))
                    }
                }

            // MARK: - MY 탭 웹 서브뷰 (#44)

            // '커뮤니티 활동'을 MY 탭 스택에 push한다. 커뮤니티 웹뷰와 같은 origin(테스트용 도메인 오버라이드 포함)과
            // 최신 토큰을 써서, 세션 쿠키를 가진 웹뷰에 다른 origin이 실리거나 옛 토큰이 주입되지 않게 한다.
            case .myPage(.delegate(.communityActivityRequested)):
                guard
                    let base = state.home.url,
                    let url = CommunityFeature.myActivityURL(base: base)
                else { return .none }
                state.myPage.path.append(.communityDetail(.init(url: url, accessToken: state.home.accessToken)))
                return .none

            // MY에서 바꾼 사진을 커뮤니티 헤더에 바로 반영한다. 탭 진입 재조회에만 맡기면
            // 삭제·업로드가 끝나기 전에 홈으로 넘어온 경우 변경 전 사진이 남는다.
            case let .myPage(.delegate(.profileImageChanged(url))):
                return .send(.home(.myProfileImageChanged(url.flatMap(URL.init(string:)))))

            // MY(탭이든 커뮤니티에 쌓인 것이든)에서 프로필을 저장하면 열린 웹뷰 모두가 내 프로필을 다시 불러오게 한다(jiu-jitsu-frontend#413).
            case .myPage(.delegate(.profileUpdated)), .home(.delegate(.profileUpdated)):
                return .merge(
                    .send(.home(.session(.profileUpdated))),
                    .send(.competition(.session(.profileUpdated))),
                    .send(.myPage(.session(.profileUpdated)))
                )

            // MY 탭 웹 서브뷰는 로그인한 사람만 여는 화면(커뮤니티 활동·차단한 회원)이라 웹의 대기 중 행위를 되살릴 일이 없어
            // 웹발 로그인(pendingWebLoginTab)으로 표시하지 않는다.
            case .myPage(.delegate(.webSubview(.loginPromptRequested))):
                return .send(.internal(.showLoginPromptAlert))

            case .myPage(.delegate(.webSubview(.loginModalRequested))):
                return .send(.internal(.showLoginModal))

            // '차단한 회원'(#56)을 MY 스택(설정 위)에 push한다. '커뮤니티 활동'과 같은 이유로 리스트 웹뷰의 origin·최신 토큰을 쓴다.
            case .myPage(.delegate(.settings(.blockedUsersRequested))):
                guard
                    let base = state.home.url,
                    let url = CommunityFeature.blockedUsersURL(base: base)
                else { return .none }
                state.myPage.path.append(.communityDetail(.init(url: url, accessToken: state.home.accessToken)))
                return .none

            // MARK: - 대회 탭 웹 (#240)

            // 비로그인 관심 등록 등 → 커뮤니티와 같이 로그인 안내. 로그인하면 대회 탭에 머물러 웹이 하던 행위로 돌아간다.
            case .competition(.delegate(.webSubview(.loginPromptRequested))):
                state.pendingWebLoginTab = .competition
                return .send(.internal(.showLoginPromptAlert))

            case .competition(.delegate(.webSubview(.loginModalRequested))):
                state.pendingWebLoginTab = .competition
                return .send(.internal(.showLoginModal))

            // 관심 대회 첫 등록 시트의 '알림 받기'(#257). 웹은 홈 피드(글 속 대회 카드)·글 상세·알림함·대회 화면 어디서든 보내므로
            // 모든 탭의 웹을 한곳에서 받는다.
            case let .competition(.delegate(.competitionAlertsEnabled(competitionId))),
                 let .home(.delegate(.competitionAlertsEnabled(competitionId))),
                 let .myPage(.delegate(.webSubview(.competitionAlertsEnabled(competitionId)))):
                return enableCompetitionAlerts(competitionId: competitionId, state: state)

            // 설정 › 알림에서 '관심 대회 알림'을 켬(#257). 웹의 '알림 받기'와 같이 기기 알림 상태를 보고 안내한다.
            // 안내 알럿은 이 화면의 최상위 덮개라 MY 스택에 쌓인 설정 화면 위에도 그려진다.
            case .myPage(.delegate(.settings(.competitionAlertTurnedOn))):
                return enableCompetitionAlerts(competitionId: nil, state: state)

            // 대회 탭에서 연 알림함을 닫음(#258) → 홈의 새 알림 점을 다시 조회한다. 대회 탭의 종도 같은 값을 그린다.
            case .competition(.delegate(.unreadNotificationRefreshRequested)):
                return .send(.home(.unreadNotificationRefreshRequested))

            // 대회 상세의 '커뮤니티에서 더 보기'(#250). 대회 스택과 홈에 쌓인 화면을 닫아 피드가 바로 보이게 한 뒤 홈으로 간다.
            case .competition(.delegate(.homeFeedRequested)):
                state.competition.path.removeAll()
                state.home.path.removeAll()
                state.home.detailCover = nil
                state.home.coverPath.removeAll()
                return .send(.view(.tabSelected(.home)))

            // 끝난 대회의 '내 기록에 남기기'(#250). 웹은 비로그인이면 로그인 안내를 대신 보내지만, 웹과 앱의 로그인 상태가
            // 어긋났을 때를 대비해 앱도 막는다 — 로그인 모달을 띄우고, 로그인하면 이 대회로 이어서 연다.
            case let .competition(.delegate(.competitionRecordRequested(payload))):
                guard !state.authInfo.isGuest else {
                    state.pendingCompetitionRecord = payload
                    state.pendingWebLoginTab = .competition
                    // 연타로 로그인 창이 이미 떠 있으면 새로 만들지 않는다(입력 중인 로그인이 초기화되지 않게).
                    guard state.loginCover == nil else { return .none }
                    return .send(.internal(.showLoginModal))
                }
                Self.pushCompetitionRecord(payload, into: &state)
                return .none

            // 기록 추가 저장(#250). MY와 같이 프로필의 대회 목록을 통째로 다시 저장한다.
            // MY가 들고 있는 프로필은 앱을 켤 때 받은 값일 수 있어(로그인 직후엔 아직 받는 중), 저장 직전에 늘 새로 받아
            // 그 위에 더한다 — 그 사이 다른 곳에서 남긴 기록이 지워지지 않게.
            // 저장 결과를 보고 완료 화면('부문 추가')으로 넘어가야 하므로 입력 화면은 닫지 않는다.
            case let .competition(.path(.element(id: id, action: .competitionInfo(.delegate(.didFinishAdding(competition)))))):
                return .run { send in
                    let result = await TaskResult {
                        let profile = try await communityClient.fetchProfile()
                        return try await communityClient.updateProfile(profile.addingCompetition(competition), .competition)
                    }
                    await send(.internal(.competitionRecordSaved(id: id, competition: competition, result)))
                }

            // MARK: - DeepLink

            case let .deepLink(.competitionDetail(url, _)):
                // 대회 상세는 대회 탭 스택에 연다. 홈 상세 모달이 떠 있으면 탭을 바꿔도 가려지므로 닫는다.
                // 탭 전환이 대회 웹을 다시 만들 수 있어(주소 미정이었던 경우) 전환을 마친 뒤 상세를 쌓는다.
                state.home.detailCover = nil
                state.home.coverPath.removeAll()
                // 토큰은 갱신이 반영된 커뮤니티 쪽 값을 먼저 쓴다(대회 탭을 다시 만들 때와 같은 순서).
                let accessToken = state.home.accessToken ?? state.competition.web?.accessToken ?? state.authInfo.accessToken
                return .concatenate(
                    state.selectedTab == .competition ? .none : .send(.view(.tabSelected(.competition))),
                    .send(.competition(.openDetail(url: url, accessToken: accessToken)))
                )

            case let .deepLink(link):
                // 대회 외의 딥링크 대상은 모두 커뮤니티 영역이라, 다른 탭에 있었다면 홈으로 되돌린 뒤 넘긴다.
                // 탭바로 돌아올 때처럼 새 알림 점·내 사진도 다시 조회한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음).
                let isEnteringHome = state.selectedTab != .home
                state.selectedTab = .home
                return .merge(
                    isEnteringHome ? .send(.home(.view(.tabEntered))) : .none,
                    .send(.home(.deepLink(link)))
                )

            // 테스트용 '딥링크로 열기'도 실제 링크와 같은 라우팅을 거친다.
            case let .home(.delegate(.debugDeepLinkRequested(link))):
                return .send(.deepLink(link))

            case .greetingFinished:
                state.isGreetingShowing = false
                return .none

            case .home, .competition, .myPage:
                return .none
                
            // MARK: - Login Logic
            case .internal(.showLoginPromptAlert):
                state.isLoginPromptPresented = true
                return .none

            case .internal(.showLoginModal):
                state.loginCover = LoginFeature.State()
                return .none

            case .internal(.showDeviceNotificationAlert):
                state.isDeviceNotificationAlertPresented = true
                return .none

            case .internal(.competitionAlertsPermissionGranted):
                // 방금 허용했으면 푸시 등록·FCM 토큰 발급·서버 등록을 앱 진입 동기화와 같은 흐름으로 잇는다.
                // 비로그인은 서버에 기기를 등록할 수 없어 권한만 받아 두고, 로그인 때 FCM 동기화가 등록한다.
                guard !state.authInfo.isGuest else { return .none }
                return .run { _ in
                    await FCMAppInfoSync.syncOnAppLaunch(firebaseClient: firebaseClient, userClient: userClient)
                }

            case .view(.deviceNotificationAlertSettingsTapped):
                state.isDeviceNotificationAlertPresented = false
                return .run { _ in
                    // 앱 설정 첫 화면이 아니라 이 앱의 알림 설정으로 바로 간다(iOS 16+).
                    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                    await openURL(url)
                }

            case .view(.deviceNotificationAlertDismissed):
                state.isDeviceNotificationAlertPresented = false
                return .none

            case .internal(.performWebLogout):
                guard !state.isLoggingOut else { return .none }
                state.isLoggingOut = true
                // 서버 세션 정리 실패는 로컬 로그아웃을 막지 않는다(토큰은 signOut으로 정리).
                // 게스트 전환(webLogoutCompleted)은 FCM 토큰 폐기까지 끝낸 뒤에 한다. 먼저 전환하면
                // 그 사이 새 로그인이 폐기 직전의 토큰을 새 계정에 등록할 수 있다(#269).
                return .run { send in
                    // 서버가 이 기기의 토큰 연결을 지우도록 함께 보낸다.
                    let fcmToken = firebaseClient.loadCachedToken().flatMap { $0.isEmpty ? nil : $0 }
                    _ = try? await authClient.serverLogout(fcmToken)
                    await authClient.signOut()
                    // 서버 요청이 실패해(오프라인 등) 연결이 남아도 이전 계정 푸시가 오지 않게 기기 토큰도 폐기한다.
                    await Self.discardDeviceFCMToken(firebaseClient, context: "logout")
                    await send(.internal(.webLogoutCompleted))
                }

            case .internal(.webLogoutCompleted):
                state.isLoggingOut = false
                Self.resetToGuest(&state)
                return .merge(Self.broadcastLoggedOut(), .cancel(id: CancelID.competitionAlerts))

            case let .internal(.sessionEvent(event)):
                // 게스트 상태에서 들어온 잔여 이벤트는 무시한다(로그아웃 직후 등).
                guard !state.authInfo.isGuest else { return .none }
                switch event {
                case let .tokenRefreshed(accessToken, _):
                    // 네이티브 API가 갱신한 토큰을 웹뷰에도 동기화.
                    return .merge(
                        .send(.home(.session(.loggedIn(accessToken: accessToken)))),
                        .send(.competition(.session(.loggedIn(accessToken: accessToken)))),
                        .send(.myPage(.session(.loggedIn(accessToken: accessToken))))
                    )
                case .sessionExpired:
                    return .send(.internal(.handleSessionExpired))
                }

            case let .internal(.tokenRefreshSucceeded(accessToken)):
                state.isRefreshingWebToken = false
                // 갱신 "응답"이므로 `.loggedIn`(중복 제거되는 수동 동기화)이 아니라 `.tokenRefreshed`로 내린다.
                // 다른 요청이 이미 갱신을 마쳐 토큰 값이 그대로여도, 요청한 웹뷰는 응답을 받아야 한다.
                return .merge(
                    .send(.home(.session(.tokenRefreshed(accessToken: accessToken)))),
                    .send(.competition(.session(.tokenRefreshed(accessToken: accessToken)))),
                    .send(.myPage(.session(.tokenRefreshed(accessToken: accessToken))))
                )

            case .internal(.tokenRefreshFailed):
                // 웹에 보낼 "일시 실패" 메시지가 없어, 요청한 웹뷰는 자체 타임아웃으로 그 호출만 실패 처리한다.
                // 다음 만료 감지 때 다시 갱신할 수 있도록 진행 표시만 푼다.
                state.isRefreshingWebToken = false
                return .none

            case .internal(.handleSessionExpired):
                state.isRefreshingWebToken = false
                // refresh 토큰까지 만료 — 로컬 토큰만 정리하고 게스트로 전환한다(서버 세션은 이미 죽음).
                Self.resetToGuest(&state)
                return .merge(
                    .run { _ in await authClient.signOut() },
                    .cancel(id: CancelID.competitionAlerts),
                    .send(.home(.session(.sessionExpired))),
                    .send(.competition(.session(.sessionExpired)))
                )

            case let .internal(.competitionRecordSaved(id, competition, .success(profile))):
                // MY의 대회 기록 목록에도 바로 보이게 MY가 가진 프로필을 바꾼다.
                // 저장 중 로그아웃·세션 만료로 게스트가 됐으면 이전 계정의 프로필을 다시 넣지 않는다.
                guard !state.authInfo.isGuest else { return .none }
                state.myPage.communityProfile = profile
                // 저장 중 입력 화면이 닫혔으면(예외적) 돌려줄 곳이 없다.
                guard case .competitionInfo? = state.competition.path[id: id] else { return .none }
                return .send(.competition(.path(.element(id: id, action: .competitionInfo(.saveFinished(.succeeded(competition)))))))

            case let .internal(.competitionRecordSaved(id, _, .failure(error))):
                Log.trace("Failed to add competition from competition tab: \(error)", category: .network, level: .error)
                // 입력 화면이 실패를 안내하고 입력값을 지켜 다시 저장하게 한다(MY와 같은 처리).
                guard case .competitionInfo? = state.competition.path[id: id] else { return .none }
                return .send(.competition(.path(.element(id: id, action: .competitionInfo(.saveFinished(.failed))))))

            case .view(.loginPromptLoginTapped):
                state.isLoginPromptPresented = false
                return .send(.internal(.showLoginModal))

            case .view(.loginPromptDismissed):
                state.isLoginPromptPresented = false
                return .none

            case .view(.loginPromptCancelTapped):
                state.isLoginPromptPresented = false
                // 웹발 로그인 알럿을 취소하면 그 웹의 대기 중 행위(pendingAction)를 폐기시킨다.
                return Self.cancelPendingWebLogin(&state)

            case let .loginCover(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo), let .didSignup(newAuthInfo):
                    // 웹발 로그인(커뮤니티·대회)은 탭 전환 없이 그대로 두어 원래 행위로 복귀시킨다.
                    // 그 외에는 기존 회원 로그인이면 MY 탭, 신규 가입이면 항상 홈 탭으로 보낸다(#72).
                    let isSignup = if case .didSignup = delegateAction { true } else { false }
                    let cameFromWeb = state.pendingWebLoginTab != nil
                    state.pendingWebLoginTab = nil
                    let pendingCompetitionRecord = state.pendingCompetitionRecord
                    state.pendingCompetitionRecord = nil
                    state.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
                    state.loginCover = nil
                    // 비로그인 MY에서 열어 둔 설정 등은 닫고, 같은 MY를 로그인 상태로 보인다(#242).
                    // 웹발 로그인이어도 닫는다 — 비로그인으로 연 설정이 남으면 로그인했는데도 '로그인' 줄만 보인다.
                    state.myPage.path.removeAll()
                    state.myPage.isMoreMenuPresented = false
                    if !cameFromWeb {
                        state.selectedTab = isSignup ? .home : .myPage
                    }
                    // 비로그인으로 누른 '내 기록에 남기기'(#250)를 이어서 연다. 프로필은 아래 loadProfile로 아직 받는 중이라
                    // 띠·체급 기본값 없이 열고, 저장 때 프로필이 없으면 그때 받아 온다.
                    if let pendingCompetitionRecord {
                        Self.pushCompetitionRecord(pendingCompetitionRecord, into: &state)
                    }
                    // 웹 세션 동기화: 새 access token을 커뮤니티·대회 웹뷰에 주입(있을 때만).
                    let syncWeb: Effect<Action> = newAuthInfo.accessToken.map {
                        .merge(
                            .send(.home(.session(.loggedIn(accessToken: $0)))),
                            .send(.competition(.session(.loggedIn(accessToken: $0))))
                        )
                    } ?? .none
                    return .merge(
                        .send(.myPage(.internal(.loadProfile))),
                        syncWeb,
                        .run { _ in
                            await FCMAppInfoSync.syncAfterLoginSuccess(
                                firebaseClient: self.firebaseClient,
                                userClient: self.userClient
                            )
                        }
                    )

                case .skipLogin:
                    // 웹발 로그인을 취소하면 그 웹의 대기 중 행위(pendingAction)를 폐기시킨다.
                    state.loginCover = nil
                    return Self.cancelPendingWebLogin(&state)
                }

            case .loginCover, .view, .internal:
                return .none

            }
        }
        .ifLet(\.$loginCover, action: \.loginCover) {
            LoginFeature()
        }

        // 띄울 탭은 어떤 액션 뒤에든 다시 맞춘다. 고른 탭은 탭바·로그인 완료·딥링크 등 여러 곳에서 바뀌고,
        // 홈 피드 덮개는 홈 웹의 신호로 걷힌다.
        Reduce { state, _ in
            Self.mountTabsIfNeeded(&state)
            return .none
        }
    }

    /// 고른 탭은 바로 띄우고, 홈 피드 덮개가 걷히면 나머지 탭도 띄운다(#271).
    /// 불러오기가 실패해 덮개가 걷혀도 띄운다 — 홈이 할 일을 마쳤으니 다른 탭을 미룰 이유가 없다.
    /// 인사 장면 중에는 미뤘다가 끝나면 띄운다(#207).
    private static func mountTabsIfNeeded(_ state: inout State) {
        if !state.mountedTabs.contains(state.selectedTab) {
            state.mountedTabs.insert(state.selectedTab)
        }
        let allTabs = Set(Tab.allCases)
        guard state.mountedTabs != allTabs, !state.home.isLoading, !state.isGreetingShowing else { return }
        state.mountedTabs = allTabs
    }

    /// 설정 › 알림의 '관심 대회 알림'을 켜고 기기 알림 상태를 본다(#257).
    /// 이미 허용이면 할 일이 없고, 거절(또는 기기 설정에서 끔)이면 앱이 다시 물을 수 없어 설정 앱으로 안내한다.
    /// 한 번도 묻지 않았으면 iOS 설정에 알림 줄조차 없으니 여기서 시스템 권한 창을 띄운다.
    private func enableCompetitionAlerts(competitionId: String?, state: State) -> Effect<Action> {
        Log.trace("관심 대회 알림 켬: competitionId=\(competitionId ?? "-")", category: .view, level: .info)
        // 회원별 설정이라 지금 로그인한 회원에 저장한다(비로그인이면 저장하지 않는다).
        let userId = state.authInfo.isGuest ? nil : state.authInfo.userInfo?.userId
        return .run { send in
            competitionAlertSettingClient.setEnabled(true, userId)
            switch await notificationPermissionClient.status() {
            case .granted:
                return
            case .denied:
                await send(.internal(.showDeviceNotificationAlert))
            case .notDetermined:
                if await firebaseClient.requestPermission() {
                    await send(.internal(.competitionAlertsPermissionGranted))
                }
            }
        }
        .cancellable(id: CancelID.competitionAlerts, cancelInFlight: true)
    }

    /// 로그아웃·탈퇴·세션 만료 — 게스트로 바꾸고 이전 계정의 화면을 정리한 뒤 홈으로 보낸다.
    private static func resetToGuest(_ state: inout State) {
        state.authInfo = .guest
        state.isDeviceNotificationAlertPresented = false
        state.pendingWebLoginTab = nil
        state.pendingCompetitionRecord = nil
        // 이전 계정으로 대회 탭에 쌓아 둔 상세·프로필도 닫는다.
        state.competition.path.removeAll()
        // MY 스택에 열어 둔 설정·웹 화면도 함께 닫힌다.
        state.myPage = MyProfileFeature.State(authInfo: .guest)
        // 이전 계정으로 커뮤니티에 쌓아 둔 MY 화면도 닫는다(#197).
        CommunityFeature.closeMyProfiles(into: &state.home)
        state.selectedTab = .home
    }

    /// 대회 상세 위에 대회명·연도를 채운 기록 추가를 쌓는다(#250). 띠·체급 기본값은 MY와 같이 프로필에서 가져온다.
    private static func pushCompetitionRecord(_ payload: OpenCompetitionRecordPayload, into state: inout State) {
        // 연타·중복 전달로 입력 화면이 겹쳐 쌓이지 않게 한다.
        if case .competitionInfo? = state.competition.path.last { return }
        let profile = state.myPage.communityProfile
        state.competition.path.append(.competitionInfo(
            CompetitionInfoFeature.State(
                prefilledName: payload.name,
                year: payload.year,
                currentBelt: profile?.beltRank,
                recentWeightLimit: profile?.competitions.recentWeightLimit
            )
        ))
    }

    /// 로그아웃·탈퇴 — 이 기기로 이전 계정 푸시가 가지 않게 FCM 토큰을 폐기한다.
    /// 캐시를 남기면 다음 로그인(syncAfterLoginSuccess)이 폐기된 토큰을 서버에 다시 등록하므로 함께 지운다.
    /// 폐기 중 토큰 콜백이 캐시를 다시 채울 수 있어 캐시는 폐기 뒤에 지운다. 폐기가 실패하면
    /// 앱 진입·복귀와 다음 토큰 발급 때 다시 시도한다(`FirebaseClientFactory`).
    private static func discardDeviceFCMToken(_ firebaseClient: FirebaseClient, context: String) async {
        do {
            try await firebaseClient.deleteFCMToken()
        } catch {
            Log.trace("FCM token deletion after \(context) failed: \(error)", category: .system, level: .error)
        }
        firebaseClient.clearCachedToken()
    }

    /// 네이티브 로그아웃을 홈·대회 웹 세션에도 알린다.
    private static func broadcastLoggedOut() -> Effect<Action> {
        .merge(
            .send(.home(.session(.loggedOut))),
            .send(.competition(.session(.loggedOut)))
        )
    }

    /// 웹발 로그인을 취소 — 그 웹이 보관한 행위(글쓰기·관심 등록 등)를 버리게 한다.
    private static func cancelPendingWebLogin(_ state: inout State) -> Effect<Action> {
        let tab = state.pendingWebLoginTab
        state.pendingWebLoginTab = nil
        state.pendingCompetitionRecord = nil
        switch tab {
        case .home:
            return .send(.home(.session(.loginCancelled)))
        case .competition:
            return .send(.competition(.session(.loginCancelled)))
        case .myPage, nil:
            return .none
        }
    }
}
