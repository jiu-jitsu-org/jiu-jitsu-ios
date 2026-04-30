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
        
        @CasePathable
        public enum ViewAction: Sendable {
            case tabSelected(Tab)
        }
        
        public enum InternalAction: Sendable {
            case showLoginModal
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
                    case .home:
                        state.selectedTab = tab
                    case .myPage, .settings:
                        return .send(.internal(.showLoginModal))
                    }
                } else {
                    state.selectedTab = tab
                }
                return .none

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
            case .internal(.showLoginModal):
                state.loginCover = LoginFeature.State()
                return .none
                
            case let .loginCover(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo):
                    state.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
                    state.settings.authInfo = newAuthInfo
                    state.selectedTab = .myPage
                    state.loginCover = nil
                    return .run { _ in
                        await FCMAppInfoSync.syncAfterLoginSuccess(
                            firebaseClient: self.firebaseClient,
                            userClient: self.userClient
                        )
                    }
                    
                case .skipLogin:
                    state.loginCover = nil
                    return .none
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
