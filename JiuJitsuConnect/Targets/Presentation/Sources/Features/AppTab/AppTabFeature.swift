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

        @CasePathable
        public enum ViewAction: Sendable {
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
        }
    }

    // MARK: - Dependencies
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.authClient) var authClient

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
            case let .view(.tabSelected(tab)):
                if state.authInfo.isGuest {
                    switch tab {
                    case .home, .settings:
                        state.selectedTab = tab
                    case .myPage:
                        return .send(.internal(.showLoginPromptAlert))
                    }
                } else {
                    state.selectedTab = tab
                }
                return .none

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
                    .send(.internal(.showLoginModal))
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

            case .home(.delegate(.logoutRequested)):
                return .send(.internal(.performWebLogout))

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
                case let .didLogin(newAuthInfo):
                    // 커뮤니티발 로그인은 탭 전환 없이 그대로 두어 원래 행위로 복귀시킨다.
                    let cameFromCommunity = state.pendingCommunityLogin
                    state.pendingCommunityLogin = false
                    state.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
                    state.settings.authInfo = newAuthInfo
                    state.loginCover = nil
                    if !cameFromCommunity {
                        state.selectedTab = .myPage
                    }
                    // 웹 세션 동기화: 새 access token을 커뮤니티 웹뷰에 주입(있을 때만).
                    let syncWeb: Effect<Action> = newAuthInfo.accessToken.map {
                        .send(.home(.session(.loggedIn(accessToken: $0, expiresAt: nil))))
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
