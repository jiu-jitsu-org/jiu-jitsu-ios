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
        case main = "홈"
        case community = "커뮤니티"
        case myPage = "MY"
    }
    
    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .main
        
        // 각 탭의 독립적인 State
        var main: MainFeature.State
        var community: CommunityFeature.State
        var myPage: MyProfileFeature.State
        
        // 로그인 모달
        @Presents var loginCover: LoginFeature.State?
        
        var authInfo: AuthInfo
        
        // 초기화 시 필요한 정보 주입 (예: AuthInfo)
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
            self.main = MainFeature.State(authInfo: authInfo)
            self.community = CommunityFeature.State()
            self.myPage = MyProfileFeature.State(authInfo: authInfo)
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        
        // 자식 Feature 액션 연결
        case main(MainFeature.Action)
        case community(CommunityFeature.Action)
        case myPage(MyProfileFeature.Action)
        
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
        // 1. 각 자식 리듀서를 Scope로 연결
        Scope(state: \.main, action: \.main) {
            MainFeature()
        }
        Scope(state: \.community, action: \.community) {
            CommunityFeature()
        }
        Scope(state: \.myPage, action: \.myPage) {
            MyProfileFeature()
        }
        
        // 2. 탭 바 자체 로직 처리
        Reduce { state, action in
            switch action {
            case let .view(.tabSelected(tab)):
                if state.authInfo.isGuest {
                    switch tab {
                    case .main, .community:
                        state.selectedTab = tab
                    case .myPage:
                        return .send(.internal(.showLoginModal))
                    }
                } else {
                    state.selectedTab = tab
                }
                return .none
                
            case .main(.delegate(.didLogoutSuccessfully)):
                state.authInfo = .guest
                state.main = MainFeature.State(authInfo: .guest)
                state.myPage = MyProfileFeature.State(authInfo: .guest)
                state.selectedTab = .main
                return .none

            case let .main(.delegate(.didLogin(newAuthInfo))):
                state.authInfo = newAuthInfo
                state.myPage.authInfo = newAuthInfo
                return .none
                
            case .main, .community, .myPage:
                return .none
                
                // MARK: - Login Logic
            case .internal(.showLoginModal):
                state.loginCover = LoginFeature.State()
                return .none
                
            case let .loginCover(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case let .didLogin(newAuthInfo):
                    state.authInfo = newAuthInfo
                    state.main.authInfo = newAuthInfo
                    state.myPage.authInfo = newAuthInfo
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

// TODO: - CommunityFeature.swift (임시)
@Reducer
public struct CommunityFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable { public init() {} }
    
    public enum Action: Sendable {}
    
    public var body: some ReducerOf<Self> { EmptyReducer() }
}
