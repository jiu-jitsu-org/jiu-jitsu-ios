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
    }

    public var body: some View {
        ZStack {
            // 탭별 NavigationStack을 모두 유지하여 탭 전환 시 상태가 보존되도록 한다.
            // 탭바는 오버레이가 아니라 각 NavigationStack root view의 safeAreaInset으로 붙인다.
            // → UIKit hidesBottomBarWhenPushed처럼 push/pop 트랜지션 하나로 root 콘텐츠와
            //   탭바가 같은 커브로 함께 밀려나가고 돌아온다. (별도 탭바 애니메이션이 있으면
            //   NavigationStack 트랜지션과 커브·타이밍이 어긋나고, pop 중 탭바 자리에
            //   root 배경색이 잠깐 비쳤다.) push된 destination은 root의 safeAreaInset 영향을
            //   받지 않아 탭바 영역까지 풀스크린으로 차지한다.
            tabContainer(for: .home) {
                NavigationStack(
                    path: $store.scope(state: \.home.path, action: \.home.path)
                ) {
                    CommunityView(store: store.scope(state: \.home, action: \.home))
                        .safeAreaInset(edge: .bottom, spacing: 0) { bottomTabBar }
                } destination: { destinationStore in
                    switch destinationStore.case {
                    case let .detail(detailStore):
                        CommunityDetailView(store: detailStore)
                    }
                }
            }
            tabContainer(for: .myPage) {
                NavigationStack {
                    MyProfileView(store: store.scope(state: \.myPage, action: \.myPage))
                        .safeAreaInset(edge: .bottom, spacing: 0) { bottomTabBar }
                }
            }
            tabContainer(for: .settings) {
                NavigationStack {
                    SettingsView(store: store.scope(state: \.settings, action: \.settings))
                        .safeAreaInset(edge: .bottom, spacing: 0) { bottomTabBar }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.component.navibar.container.background)
        .fullScreenCover(
            item: $store.scope(state: \.loginCover, action: \.loginCover)
        ) { loginStore in
            LoginView(store: loginStore)
        }
        // OPEN_SUBVIEW(modal) — 게시글 상세를 모달로 띄운다. 모달 내부의 중첩 OPEN_SUBVIEW는
        // 자체 NavigationStack(coverPath)에 push되어 모달 위 모달 중첩을 피한다.
        .fullScreenCover(
            item: $store.scope(state: \.home.detailCover, action: \.home.detailCover)
        ) { coverStore in
            NavigationStack(
                path: $store.scope(state: \.home.coverPath, action: \.home.coverPath)
            ) {
                CommunityDetailView(store: coverStore)
            } destination: { destinationStore in
                switch destinationStore.case {
                case let .detail(detailStore):
                    CommunityDetailView(store: detailStore)
                }
            }
        }
        .appAlert(
            isPresented: Binding(
                get: { store.isLoginPromptPresented },
                set: { if !$0 { store.send(.view(.loginPromptDismissed)) } }
            ),
            configuration: loginPromptAlertConfiguration
        )
        // 리스트 웹뷰가 요청한 확인 알럿·선택 시트를 최상위에서 그려 GNB·하단 탭바까지 덮는다.
        // (웹뷰는 자기 프레임 밖을 딤 처리할 수 없어 이 표면은 네이티브가 소유한다.)
        .webBridgeDialogs(
            confirmDialog: store.home.pendingConfirmDialog,
            selectSheet: store.home.pendingSelectSheet,
            onConfirmButton: { store.send(.home(.view(.confirmDialogButtonTapped($0)))) },
            onConfirmDismiss: { store.send(.home(.view(.confirmDialogDismissed))) },
            onSelectSubmit: { store.send(.home(.view(.selectSheetSubmitted(value: $0, customText: $1)))) },
            onSelectDismiss: { store.send(.home(.view(.selectSheetDismissed))) }
        )
        .onAppear { store.send(.view(.onAppear)) }
    }

    // 게스트가 인증 필요 동작(MY 탭 진입·커뮤니티 행위 등)을 시도할 때 노출되는 공통 로그인 유도 알럿.
    // 특정 화면에 종속되지 않도록 문구를 일반화해 여러 진입점에서 그대로 재사용한다.
    private var loginPromptAlertConfiguration: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "로그인하고 더 많은\n기능을 이용해보세요",
            message: "커뮤니티 참여와 프로필 설정이 가능해요.",
            primaryButton: .init(
                title: "로그인",
                style: .primary,
                action: { store.send(.view(.loginPromptLoginTapped)) }
            ),
            secondaryButton: .init(
                title: "닫기",
                style: .neutral,
                action: { store.send(.view(.loginPromptCancelTapped)) }
            )
        )
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
        .padding(.horizontal, 20)
        .background(Color.component.navibar.container.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.component.navibar.container.divider)
                .frame(height: 1)
        }
        // Figma drop shadow(y=-4, blur=12, #000000 8%) → SwiftUI radius ≈ blur/2
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: -4
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
            VStack(spacing: 4) {
                asset.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
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
