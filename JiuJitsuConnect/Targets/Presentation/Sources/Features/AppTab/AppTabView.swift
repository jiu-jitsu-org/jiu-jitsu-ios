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
        TabView(selection: $store.selectedTab.sending(\.view.tabSelected)) {
            
            // 탭 1: 홈
            NavigationStack {
                CommunityView(store: store.scope(state: \.home, action: \.home))
            }
            .tabItem {
                Image(systemName: "house")
                Text("홈")
            }
            .tag(AppTabFeature.Tab.home)
            
            // 탭 2: 마이페이지
            NavigationStack {
                MyProfileView(store: store.scope(state: \.myPage, action: \.myPage))
            }
            .tabItem {
                Image(systemName: "person")
                Text("MY")
            }
            .tag(AppTabFeature.Tab.myPage)

            // 탭 3: 설정
            NavigationStack {
                SettingsView(store: store.scope(state: \.settings, action: \.settings))
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("설정")
            }
            .tag(AppTabFeature.Tab.settings)
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
        .fullScreenCover(
            item: $store.scope(state: \.loginCover, action: \.loginCover)
        ) { loginStore in
            LoginView(store: loginStore)
        }
    }
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
