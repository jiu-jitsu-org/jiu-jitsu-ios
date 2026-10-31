//
//  AppTabFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit

@Reducer
public struct AppTabFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        // 401 인터셉터가 방송하는 세션 이벤트 구독. AppTab 생명주기 동안만 유지한다.
        case sessionObserver
    }

    public enum Tab: String, CaseIterable, Equatable, Sendable {
        case home = "홈"
        case myPage = "MY"
        case settings = "설정"
    }

    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .home

        // 각 탭의 독립적인 State
        var home: CommunityFeature.State
        var myPage: MyProfileFeature.State
        var settings: SettingsFeature.State

        // 로그인 모달
        @Presents var loginCover: LoginFeature.State?
        // 게스트가 인증 필요 탭(MY)을 탭했을 때 노출되는 공통 AppAlert 표시 여부
        var isLoginPromptPresented: Bool = false
        // 로그인 모달이 커뮤니티 웹뷰의 행위(글쓰기 등)에서 트리거됐는지 여부.
        // true면 로그인 성공 시 탭 전환 없이 커뮤니티에 머물러 행위를 복귀시키고,
        // 취소 시 웹에 AUTH_LOGIN_CANCELLED를 보내 대기 중 행위를 폐기시킨다.
        var pendingCommunityLogin: Bool = false
        // 세션 이벤트 구독을 onAppear 중복 호출에도 한 번만 시작하기 위한 가드.
        var didStartSessionObserver: Bool = false
        // 웹뷰 위임 토큰 갱신이 진행 중인지. 리스트·상세 여러 웹뷰가 동시에 만료를 감지해도
        // 갱신은 한 번만 태우고 결과를 모두에게 전파한다. (refreshToken은 서버에서 1회용으로 회전)
        var isRefreshingWebToken: Bool = false

        var authInfo: AuthInfo

        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
            // 이미 로그인 상태로 진입하면 WEBVIEW_READY 핸드셰이크 때 토큰을 주입하도록 전달.
            self.home = CommunityFeature.State(accessToken: authInfo.accessToken)
            self.myPage = MyProfileFeature.State(authInfo: authInfo)
            self.settings = SettingsFeature.State(authInfo: authInfo)
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        // 자식 Feature 액션 연결
        case home(CommunityFeature.Action)
        case myPage(MyProfileFeature.Action)
        case settings(SettingsFeature.Action)

        case loginCover(PresentationAction<LoginFeature.Action>)

        // 부모(AppFeature)가 파싱해 넘긴 유니버설 링크.
        case deepLink(DeepLink)

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
        }

        public enum InternalAction: Sendable {
            case showLoginPromptAlert
            case showLoginModal
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
        }
    }

    // MARK: - Dependencies
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.authSessionEventClient) var authSessionEventClient

    public var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            CommunityFeature()
        }
        Scope(state: \.myPage, action: \.myPage) {
            MyProfileFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
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
                // 다른 탭에서 커뮤니티로 돌아오면 새 알림 점을 갱신한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음).
                if tab == .home, state.selectedTab != .home {
                    state.selectedTab = tab
                    return .send(.home(.view(.tabEntered)))
                }
                if state.authInfo.isGuest {
                    switch tab {
                    case .home, .settings:
                        state.selectedTab = tab
                    case .myPage:
                        return .send(.internal(.showLoginPromptAlert))
                    }
                } else {
                    // 다른 탭에서 MY로 돌아오면 프로필을 재조회한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음, #69).
                    let isEnteringMyPage = tab == .myPage && state.selectedTab != .myPage
                    state.selectedTab = tab
                    if isEnteringMyPage {
                        return .send(.myPage(.view(.tabEntered)))
                    }
                }
                return .none

            case .view(.sceneBecameActive):
                // MY 탭을 보고 있을 때만 포그라운드 복귀 재조회 (#69)
                guard state.selectedTab == .myPage, !state.authInfo.isGuest else { return .none }
                return .send(.myPage(.view(.sceneBecameActive)))

            case .settings(.delegate(.loginRequested)):
                return .send(.internal(.showLoginModal))

            case .settings(.delegate(.didLogoutSuccessfully)):
                state.authInfo = .guest
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.settings = SettingsFeature.State(authInfo: .guest)
                state.selectedTab = .home
                // 웹 세션도 함께 정리.
                return .send(.home(.session(.loggedOut)))

            case .settings(.delegate(.didWithdrawSuccessfully)):
                state.authInfo = .guest
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.settings = SettingsFeature.State(authInfo: .guest)
                state.selectedTab = .home
                return .merge(
                    .send(.home(.session(.loggedOut))),
                    // 로컬 세션 정리를 끝낸 뒤 로그인 모달을 띄운다. 먼저 띄우면 새로 로그인한 토큰을
                    // 뒤늦은 signOut이 지우거나, 새 로그인이 폐기 직전의 FCM 토큰을 등록할 수 있다.
                    .run { send in
                        await authClient.signOut()
                        // 탈퇴 기기로 푸시가 가지 않게 FCM 토큰을 폐기한다. 캐시를 남기면 다음 로그인
                        // (syncAfterLoginSuccess)이 폐기된 토큰을 서버에 다시 등록하므로 함께 지운다.
                        firebaseClient.clearCachedToken()
                        do {
                            try await firebaseClient.deleteFCMToken()
                        } catch {
                            Log.trace("FCM token deletion after withdrawal failed: \(error)", category: .system, level: .error)
                        }
                        await send(.internal(.showLoginModal))
                    }
                )

            // MARK: - Community Web Bridge Delegate
            case let .home(.delegate(.loginPromptRequested(reason))):
                // 커뮤니티 웹뷰의 비로그인 행위 → "로그인이 필요해요" 안내 알럿(소프트 유도).
                state.pendingCommunityLogin = true
                Log.trace("커뮤니티 로그인 알럿 요청: reason=\(reason ?? "-")", category: .view, level: .info)
                return .send(.internal(.showLoginPromptAlert))

            case let .home(.delegate(.loginModalRequested(reason))):
                // 커뮤니티 웹뷰의 비로그인 행위 → 로그인 모달 즉시 노출(다이렉트).
                state.pendingCommunityLogin = true
                Log.trace("커뮤니티 로그인 모달 요청: reason=\(reason ?? "-")", category: .view, level: .info)
                return .send(.internal(.showLoginModal))

            // 헤더의 내 사진 버튼(#128)·웹에서 내 이름 탭(#116). 탭바에서 MY를 누른 것과 같은 경로라 프로필 재조회·게스트 처리도 그대로 따른다.
            // 내 사진은 내 프로필을 뜻하므로, MY에 열어 둔 하위 화면(커뮤니티 활동 등)은 닫고 프로필 첫 화면으로 보낸다.
            // 홈의 모달 상세는 탭 전체를 덮어서, 닫지 않으면 MY로 바뀌어도 화면에 아무 변화가 없다.
            case .home(.delegate(.myTabRequested)),
                 .myPage(.delegate(.webSubview(.myTabRequested))),
                 .settings(.delegate(.webSubview(.myTabRequested))):
                if !state.authInfo.isGuest {
                    state.myPage.path.removeAll()
                    state.home.detailCover = nil
                    state.home.coverPath.removeAll()
                }
                return .send(.view(.tabSelected(.myPage)))

            case .home(.delegate(.logoutRequested)),
                 .myPage(.delegate(.webSubview(.logoutRequested))),
                 .settings(.delegate(.webSubview(.logoutRequested))):
                return .send(.internal(.performWebLogout))

            case .home(.delegate(.tokenRefreshRequested)),
                 .myPage(.delegate(.webSubview(.tokenRefreshRequested))),
                 .settings(.delegate(.webSubview(.tokenRefreshRequested))):
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

            // MY 탭은 로그인 전용이라 웹의 대기 중 행위를 되살릴 일이 없어 커뮤니티발 로그인(pendingCommunityLogin)으로 표시하지 않는다.
            case .myPage(.delegate(.webSubview(.loginPromptRequested))),
                 .settings(.delegate(.webSubview(.loginPromptRequested))):
                return .send(.internal(.showLoginPromptAlert))

            case .myPage(.delegate(.webSubview(.loginModalRequested))),
                 .settings(.delegate(.webSubview(.loginModalRequested))):
                return .send(.internal(.showLoginModal))

            // MARK: - 설정 탭 웹 서브뷰 (#56)

            // '차단한 회원'을 설정 스택에 push한다. MY의 '커뮤니티 활동'과 같은 이유로 리스트 웹뷰의 origin·최신 토큰을 쓴다.
            case .settings(.delegate(.blockedUsersRequested)):
                guard
                    let base = state.home.url,
                    let url = CommunityFeature.blockedUsersURL(base: base)
                else { return .none }
                state.settings.path.append(.communityDetail(.init(url: url, accessToken: state.home.accessToken)))
                return .none

            // MARK: - DeepLink

            case let .deepLink(link):
                // 현재 딥링크 대상은 모두 커뮤니티 영역이라, 다른 탭에 있었다면 홈으로 되돌린 뒤 넘긴다.
                // 탭바로 돌아올 때처럼 새 알림 점·내 사진도 다시 조회한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음).
                let isEnteringHome = state.selectedTab != .home
                state.selectedTab = .home
                return .merge(
                    isEnteringHome ? .send(.home(.view(.tabEntered))) : .none,
                    .send(.home(.deepLink(link)))
                )

            case .home, .myPage, .settings:
                return .none
                
            // MARK: - Login Logic
            case .internal(.showLoginPromptAlert):
                state.isLoginPromptPresented = true
                return .none

            case .internal(.showLoginModal):
                state.loginCover = LoginFeature.State()
                return .none

            case .internal(.performWebLogout):
                // 서버 세션 정리 실패는 로컬 로그아웃을 막지 않는다(토큰은 signOut으로 정리).
                return .run { send in
                    _ = try? await authClient.serverLogout()
                    await authClient.signOut()
                    await send(.internal(.webLogoutCompleted))
                }

            case .internal(.webLogoutCompleted):
                state.authInfo = .guest
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.settings = SettingsFeature.State(authInfo: .guest)
                state.selectedTab = .home
                return .send(.home(.session(.loggedOut)))

            case let .internal(.sessionEvent(event)):
                // 게스트 상태에서 들어온 잔여 이벤트는 무시한다(로그아웃 직후 등).
                guard !state.authInfo.isGuest else { return .none }
                switch event {
                case let .tokenRefreshed(accessToken, _):
                    // 네이티브 API가 갱신한 토큰을 웹뷰에도 동기화.
                    return .merge(
                        .send(.home(.session(.loggedIn(accessToken: accessToken)))),
                        .send(.myPage(.session(.loggedIn(accessToken: accessToken)))),
                        .send(.settings(.session(.loggedIn(accessToken: accessToken))))
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
                    .send(.myPage(.session(.tokenRefreshed(accessToken: accessToken)))),
                    .send(.settings(.session(.tokenRefreshed(accessToken: accessToken))))
                )

            case .internal(.tokenRefreshFailed):
                // 웹에 보낼 "일시 실패" 메시지가 없어, 요청한 웹뷰는 자체 타임아웃으로 그 호출만 실패 처리한다.
                // 다음 만료 감지 때 다시 갱신할 수 있도록 진행 표시만 푼다.
                state.isRefreshingWebToken = false
                return .none

            case .internal(.handleSessionExpired):
                state.isRefreshingWebToken = false
                // refresh 토큰까지 만료 — 로컬 토큰만 정리하고 게스트로 전환한다(서버 세션은 이미 죽음).
                state.authInfo = .guest
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.settings = SettingsFeature.State(authInfo: .guest)
                state.selectedTab = .home
                return .merge(
                    .run { _ in await authClient.signOut() },
                    .send(.home(.session(.sessionExpired)))
                )

            case .view(.loginPromptLoginTapped):
                state.isLoginPromptPresented = false
                return .send(.internal(.showLoginModal))

            case .view(.loginPromptDismissed):
                state.isLoginPromptPresented = false
                return .none

            case .view(.loginPromptCancelTapped):
                state.isLoginPromptPresented = false
                // 커뮤니티발 로그인 알럿을 취소하면 웹의 대기 중 행위(pendingAction)를 폐기시킨다.
                // (MY 탭 진입 알럿은 pendingCommunityLogin=false라 웹에 영향 없음)
                guard state.pendingCommunityLogin else { return .none }
                state.pendingCommunityLogin = false
                return .send(.home(.session(.loginCancelled)))

            case let .loginCover(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo), let .didSignup(newAuthInfo):
                    // 커뮤니티발 로그인은 탭 전환 없이 그대로 두어 원래 행위로 복귀시킨다.
                    // 그 외에는 기존 회원 로그인이면 MY 탭, 신규 가입이면 항상 홈 탭으로 보낸다(#72).
                    let isSignup = if case .didSignup = delegateAction { true } else { false }
                    let cameFromCommunity = state.pendingCommunityLogin
                    state.pendingCommunityLogin = false
                    state.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
                    state.settings.authInfo = newAuthInfo
                    state.loginCover = nil
                    if !cameFromCommunity {
                        state.selectedTab = isSignup ? .home : .myPage
                    }
                    // 웹 세션 동기화: 새 access token을 커뮤니티 웹뷰에 주입(있을 때만).
                    let syncWeb: Effect<Action> = newAuthInfo.accessToken.map {
                        .send(.home(.session(.loggedIn(accessToken: $0))))
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
                    // 커뮤니티발 로그인을 취소하면 웹의 대기 중 행위(pendingAction)를 폐기시킨다.
                    let cameFromCommunity = state.pendingCommunityLogin
                    state.pendingCommunityLogin = false
                    state.loginCover = nil
                    return cameFromCommunity ? .send(.home(.session(.loginCancelled))) : .none
                }

            case .loginCover, .view, .internal:
                return .none

            }
        }
        .ifLet(\.$loginCover, action: \.loginCover) {
            LoginFeature()
        }
    }
}
