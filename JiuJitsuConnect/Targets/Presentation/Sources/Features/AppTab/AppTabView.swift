//
//  AppTabView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

public struct AppTabView: View {
    @Bindable var store: StoreOf<AppTabFeature>
    
    public init(store: StoreOf<AppTabFeature>) {
        self.store = store
    }
    
    public var body: some View {
        // iOS 18+ 혹은 최신 SwiftUI에서는 $store.selectedTab.sending(\.tabSelected) 사용 가능
        // 하위 호환성을 위해 Binding(get:set:)을 명시적으로 사용할 수도 있습니다.
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            
            // 탭 1: 메인
            MainView(store: store.scope(state: \.main, action: \.main))
                .tabItem {
                    Image(systemName: "house") // 실제 에셋으로 변경 필요
                    Text("홈")
                }
                .tag(AppTabFeature.Tab.main)
            
            // 탭 2: 커뮤니티
            CommunityView(store: store.scope(state: \.community, action: \.community))
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("커뮤니티")
                }
                .tag(AppTabFeature.Tab.community)
            
            // 탭 3: 마이페이지
            MyPageView(store: store.scope(state: \.myPage, action: \.myPage))
                .tabItem {
                    Image(systemName: "person")
                    Text("MY")
                }
                .tag(AppTabFeature.Tab.myPage)
        }
        .tint(.blue) // 선택된 탭 색상
        .onAppear {
            // 탭바 배경을 흰색으로 고정 (선택 사항)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// TODO: - CommunityView.swift (임시)
public struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    public init(store: StoreOf<CommunityFeature>) { self.store = store }
    public var body: some View { Text("커뮤니티 화면") }
}

// MARK: - Preview
#Preview {
    AppTabView(
        store: Store(
            initialState: AppTabFeature.State(
                authInfo: AuthInfo(
                    accessToken: "preview_access_token",
                    refreshToken: "preview_refresh_token",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "preview@example.com",
                        nickname: "프리뷰유저",
                        profileImageUrl: nil,
                        snsProvider: "APPLE",
                        deactivatedWithinGrace: false
                    )
                )
            )
        ) {
            AppTabFeature()
        }
    )
}
