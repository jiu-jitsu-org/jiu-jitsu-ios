//
//  NotificationSettingView.swift
//  Presentation
//
//  설정 → 알림 화면. 카테고리별 수신 토글.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

private enum Style {
    static let headerHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 16
}

public struct NotificationSettingView: View {
    @Bindable var store: StoreOf<NotificationSettingFeature>
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<NotificationSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: Style.sectionSpacing) {
                        if store.showsDeviceNotificationBanner {
                            deviceNotificationBanner
                        }

                        // 카테고리별 토글 (우선순위: 보안 > 공지 > 커뮤니티 > 관심 대회 > 마케팅)
                        // 마케팅은 정통망법상 옵트인 → 기본 false.
                        SettingsSection {
                            SettingsToggleRow(
                                asset: Assets.Common.Icon.bell,
                                text: "계정·보안 알림",
                                subtitle: "로그인, 신고 처리 결과 등",
                                isLoading: !store.isLoaded,
                                isOn: Binding(
                                    get: { store.isAccountSecurityNotificationEnabled },
                                    set: { store.send(.view(.accountSecurityNotificationToggled($0))) }
                                )
                            )
                            SettingsToggleRow(
                                asset: Assets.Common.Icon.bell,
                                text: "서비스 공지 알림",
                                subtitle: "정책 변경, 공지사항",
                                isLoading: !store.isLoaded,
                                isOn: Binding(
                                    get: { store.isServiceNoticeNotificationEnabled },
                                    set: { store.send(.view(.serviceNoticeNotificationToggled($0))) }
                                )
                            )
                            SettingsToggleRow(
                                asset: Assets.Common.Icon.bell,
                                text: "커뮤니티 활동 알림",
                                subtitle: "댓글, 답글, 언급 등",
                                isLoading: !store.isLoaded,
                                isOn: Binding(
                                    get: { store.isCommunityNotificationEnabled },
                                    set: { store.send(.view(.communityNotificationToggled($0))) }
                                )
                            )
                            SettingsToggleRow(
                                asset: Assets.Common.Icon.bell,
                                text: "관심 대회 알림",
                                subtitle: "얼리버드 · 접수 마감 전날",
                                isLoading: !store.isLoaded,
                                isOn: Binding(
                                    get: { store.isCompetitionAlertEnabled },
                                    set: { store.send(.view(.competitionAlertToggled($0))) }
                                )
                            )
                            SettingsToggleRow(
                                asset: Assets.Common.Icon.bell,
                                text: "마케팅 정보 알림",
                                subtitle: "이벤트, 혜택 안내",
                                isLoading: !store.isLoaded,
                                isOn: Binding(
                                    get: { store.isMarketingNotificationEnabled },
                                    set: { store.send(.view(.marketingNotificationToggled($0))) }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .padding(.vertical, Style.verticalPadding)
                }
                .background(Color.component.background.default)
            }
        }
        .toast(
            store.toast,
            onSwipe: { store.send(.internal(.toastDismissed)) },
            onButtonTapped: { store.send(.view(.toastButtonTapped($0))) }
        )
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.view(.sceneBecameActive)) }
        }
    }

    // 기기 알림을 아직 묻지 않았거나 거절했을 때(#333). 서버 설정이 켜져 있어도 알림이 오지 않는다는 걸 알린다.
    private var deviceNotificationBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("기기 알림이 꺼져 있어요")
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.semantic.text.primary)
                Text("지금은 알림이 오지 않아요")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.semantic.text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.view(.deviceNotificationTurnOnTapped))
            } label: {
                AppButtonConfiguration(title: "켜기", size: .small)
            }
            .appButtonStyle(.primary, size: .small, height: 32)
        }
        .padding(16)
        .background(Color.semantic.surface.primarySubtle)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var headerView: some View {
        HStack {
            Button(action: { store.send(.view(.backButtonTapped)) }) {
                ZStack {
                    Assets.Common.Icon.chevronLeft.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("알림")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)

            Spacer()

            Rectangle()
                .fill(.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top))
    }
}

#Preview("Notification Setting View") {
    NavigationStack {
        NotificationSettingView(
            store: Store(initialState: NotificationSettingFeature.State()) {
                NotificationSettingFeature()
            } withDependencies: {
                $0.noticeClient = .previewValue
            }
        )
    }
}
