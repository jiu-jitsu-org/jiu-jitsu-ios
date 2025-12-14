//
//  AppTabFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import ComposableArchitecture
import Domain

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
        var myPage: MyPageFeature.State
        
        // 초기화 시 필요한 정보 주입 (예: AuthInfo)
        public init(authInfo: AuthInfo) {
            self.main = MainFeature.State(authInfo: authInfo)
            self.community = CommunityFeature.State()
            self.myPage = MyPageFeature.State(authInfo: authInfo)
        }
    }
    
    public enum Action: Equatable, Sendable {
        case tabSelected(Tab)
        
        // 자식 Feature 액션 연결
        case main(MainFeature.Action)
        case community(CommunityFeature.Action)
        case myPage(MyPageFeature.Action)
    }
    
    public var body: some ReducerOf<Self> {
        // 1. 각 자식 리듀서를 Scope로 연결
        Scope(state: \.main, action: \.main) {
            MainFeature()
        }
        Scope(state: \.community, action: \.community) {
            CommunityFeature()
        }
        Scope(state: \.myPage, action: \.myPage) {
            MyPageFeature()
        }
        
        // 2. 탭 바 자체 로직 처리
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .main, .community, .myPage:
                return .none
            }
        }
    }
}

// TODO: - CommunityFeature.swift (임시)
@Reducer
public struct CommunityFeature: Sendable {
    public init() {}
    @ObservableState public struct State: Equatable { public init() {} }
    public enum Action: Equatable, Sendable {}
    public var body: some ReducerOf<Self> { EmptyReducer() }
}
