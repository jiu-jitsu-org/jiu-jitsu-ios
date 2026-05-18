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
        // 게스트가 인증 필요 탭(MY)을 탭했을 때 노출되는 로그인 안내 팝업 (FIXME: 정식 디자인 적용 예정)
        @Presents var loginPromptAlert: AlertState<Action.LoginPromptAlert>?

        var authInfo: AuthInfo

        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
            self.home = CommunityFeature.State()
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
        case loginPromptAlert(PresentationAction<LoginPromptAlert>)

        @CasePathable
        public enum ViewAction: Sendable {
            case tabSelected(Tab)
        }

        public enum InternalAction: Sendable {
            case showLoginPromptAlert
            case showLoginModal
        }

        // AlertState<Alert> 요구사항을 충족하기 위해 Equatable 유지
        public enum LoginPromptAlert: Equatable, Sendable {
            case loginTapped
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient

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
                return .none

            case .settings(.delegate(.didWithdrawSuccessfully)):
                state.authInfo = .guest
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.settings = SettingsFeature.State(authInfo: .guest)
                state.selectedTab = .home
                return .send(.internal(.showLoginModal))

            case .home, .myPage, .settings:
                return .none
                
            // MARK: - Login Logic
            case .internal(.showLoginPromptAlert):
                // FIXME: 정식 로그인 안내 팝업 디자인이 확정되면 커스텀 컴포넌트로 교체한다.
                state.loginPromptAlert = AlertState {
                    TextState("로그인이 필요해요")
                } actions: {
                    ButtonState(action: .loginTapped) { TextState("로그인") }
                    ButtonState(role: .cancel) { TextState("취소") }
                } message: {
                    TextState("로그인하면 나의 프로필을 확인할 수 있어요.")
                }
                return .none

            case .internal(.showLoginModal):
                state.loginCover = LoginFeature.State()
                return .none

            case .loginPromptAlert(.presented(.loginTapped)):
                return .send(.internal(.showLoginModal))
                
            case let .loginCover(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo):
                    state.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
                    state.settings.authInfo = newAuthInfo
                    state.selectedTab = .myPage
                    state.loginCover = nil
                    return .merge(
                        .send(.myPage(.internal(.loadProfile))),
                        .run { _ in
                            await FCMAppInfoSync.syncAfterLoginSuccess(
                                firebaseClient: self.firebaseClient,
                                userClient: self.userClient
                            )
                        }
                    )
                    
                case .skipLogin:
                    state.loginCover = nil
                    return .none
                }
                
            case .loginCover, .loginPromptAlert, .view, .internal:
                return .none

            }
        }
        .ifLet(\.$loginCover, action: \.loginCover) {
            LoginFeature()
        }
        .ifLet(\.$loginPromptAlert, action: \.loginPromptAlert)
    }
}
