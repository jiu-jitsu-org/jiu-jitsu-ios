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

    public init(store: StoreOf<NotificationSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: Style.sectionSpacing) {
                    // 카테고리별 토글 (우선순위: 보안 > 공지 > 커뮤니티 > 마케팅)
                    // 마케팅은 정통망법상 옵트인 → 기본 false.
                    SettingsSection {
                        SettingsToggleRow(
                            asset: Assets.Common.Icon.bell,
                            text: "계정·보안 알림",
                            subtitle: "로그인, 신고 처리 결과 등",
                            isOn: Binding(
                                get: { store.isAccountSecurityNotificationEnabled },
                                set: { store.send(.view(.accountSecurityNotificationToggled($0))) }
                            )
                        )
                        SettingsToggleRow(
                            asset: Assets.Common.Icon.bell,
                            text: "서비스 공지 알림",
                            subtitle: "정책 변경, 공지사항",
                            isOn: Binding(
                                get: { store.isServiceNoticeNotificationEnabled },
                                set: { store.send(.view(.serviceNoticeNotificationToggled($0))) }
                            )
                        )
                        SettingsToggleRow(
                            asset: Assets.Common.Icon.bell,
                            text: "커뮤니티 활동 알림",
                            subtitle: "댓글, 답글, 언급 등",
                            isOn: Binding(
                                get: { store.isCommunityNotificationEnabled },
                                set: { store.send(.view(.communityNotificationToggled($0))) }
                            )
                        )
                        SettingsToggleRow(
                            asset: Assets.Common.Icon.bell,
                            text: "마케팅 정보 알림",
                            subtitle: "이벤트, 혜택 안내",
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
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
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
            }
        )
    }
}
