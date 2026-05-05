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

    private enum Metrics {
        static let tabBarHeight: CGFloat = 58
        static let tabBarHorizontalPadding: CGFloat = 20
        static let iconSize: CGFloat = 24
        static let itemSpacing: CGFloat = 4
        static let topBorderHeight: CGFloat = 1

        // Drop shadow: x=0, y=-4, blur=12, spread=0, #000000 8% (Figma 기준)
        static let shadowColor = Color.black.opacity(0.08)
        static let shadowRadius: CGFloat = 6   // SwiftUI radius ≈ Figma blur / 2
        static let shadowY: CGFloat = -4
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 탭별 NavigationStack을 모두 유지하여 탭 전환 시 상태가 보존되도록 한다
                tabContainer(for: .home) {
                    NavigationStack {
                        CommunityView(store: store.scope(state: \.home, action: \.home))
                    }
                }
                tabContainer(for: .myPage) {
                    NavigationStack {
                        MyProfileView(store: store.scope(state: \.myPage, action: \.myPage))
                    }
                }
                tabContainer(for: .settings) {
                    NavigationStack {
                        SettingsView(store: store.scope(state: \.settings, action: \.settings))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomTabBar
        }
        .background(Color.component.navibar.container.background)
        .fullScreenCover(
            item: $store.scope(state: \.loginCover, action: \.loginCover)
        ) { loginStore in
            LoginView(store: loginStore)
        }
    }

    @ViewBuilder
    private func tabContainer<Content: View>(
        for tab: AppTabFeature.Tab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isActive = store.selectedTab == tab
        content()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
    }

    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(tab: .home, asset: Assets.Bottom.Icon.home, label: "홈")
            tabBarButton(tab: .myPage, asset: Assets.Bottom.Icon.my, label: "MY")
            tabBarButton(tab: .settings, asset: Assets.Bottom.Icon.setting, label: "설정")
        }
        .frame(height: Metrics.tabBarHeight)
        .padding(.horizontal, Metrics.tabBarHorizontalPadding)
        .background(Color.component.navibar.container.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.component.navibar.container.divider)
                .frame(height: Metrics.topBorderHeight)
        }
        .shadow(
            color: Metrics.shadowColor,
            radius: Metrics.shadowRadius,
            x: 0,
            y: Metrics.shadowY
        )
    }

    private func tabBarButton(
        tab: AppTabFeature.Tab,
        asset: ImageAsset,
        label: String
    ) -> some View {
        let isSelected = store.selectedTab == tab
        let iconColor: Color = isSelected
            ? Color.component.navibar.selected.icon
            : Color.component.navibar.unselected.icon
        let labelColor: Color = isSelected
            ? Color.component.navibar.selected.label
            : Color.component.navibar.unselected.label

        return Button {
            store.send(.view(.tabSelected(tab)))
        } label: {
            VStack(spacing: Metrics.itemSpacing) {
                asset.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(Font.pretendard.buttonS)
                    .foregroundStyle(labelColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
