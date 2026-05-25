//
//  SettingsView.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import CoreKit

private enum Style {
    static let headerHeight: CGFloat = 44

    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24

    static let sectionSpacing: CGFloat = 16
}

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: Style.sectionSpacing) {
                    // MARK: - 알림 설정 진입 섹션 (카테고리별 토글은 NotificationSettingView로 분리)
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.bell, text: "알림") {
                            store.send(.view(.notificationButtonTapped))
                        }
                    }

                    // MARK: - 약관 및 정책 섹션
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.documents, text: "서비스 이용 약관") {
                            store.send(.view(.termsButtonTapped))
                        }
                        SettingsInteractiveRow(asset: Assets.Common.Icon.documents, text: "개인정보 처리 방침") {
                            store.send(.view(.privacyPolicyButtonTapped))
                        }
                    }

                    // MARK: - 버전 정보 섹션
                    SettingsSection {
                        HStack {
                            SettingsRowContent(asset: Assets.Common.Icon.version, text: "버전 정보")
                            Spacer()
                            Text(store.appVersion)
                                .font(Font.pretendard.captionM)
                                .foregroundStyle(Color.component.list.setting.valueText)
                        }
                        .frame(minHeight: SettingsListMetrics.rowHeight)
                        .padding(.horizontal, 16)
                    }

                    // MARK: - 계정 관리 섹션
                    SettingsSection {
                        if store.authInfo.isGuest {
                            SettingsInteractiveRow(asset: Assets.Common.Icon.logOut, text: "로그인") {
                                store.send(.view(.loginButtonTapped))
                            }
                        } else {
                            SettingsInteractiveRow(asset: Assets.Common.Icon.logOut, text: "로그아웃") {
                                store.send(.view(.logoutButtonTapped))
                            }
                            SettingsInteractiveRow(asset: Assets.Common.Icon.secession, text: "회원 탈퇴") {
                                store.send(.view(.withdrawalButtonTapped))
                            }
                        }
                    }
                }
                .padding(.horizontal, Style.horizontalPadding)
                .padding(.vertical, Style.verticalPadding)
            }
            .background(Color.component.background.default)
        }
        .overlay(alignment: .bottom) {
            if let toastState = store.toast {
                ToastView(
                    state: toastState,
                    onSwipe: { store.send(.internal(.toastDismissed), animation: .default) },
                    onButtonTapped: { store.send(.view(.toastButtonTapped($0)), animation: .default) }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, toastState.bottomPadding)
            }
        }
        .animation(.default, value: store.toast)
        .appAlert(
            isPresented: Binding(
                get: { store.alert != nil },
                set: { if !$0 { store.send(.view(.alertDismissed)) } }
            ),
            configuration: alertConfiguration(for: store.alert)
        )
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.notificationSetting,
                action: \.destination.notificationSetting
            )
        ) { notificationStore in
            NotificationSettingView(store: notificationStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.termsWebCover, action: \.termsWebCover)
        ) { termsStore in
            TermsWebViewView(store: termsStore)
        }
    }

    private var headerView: some View {
        HStack {
            Text("설정")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top))
    }

    // MARK: - Alert Configuration Helper
    private func alertConfiguration(for alertType: SettingsFeature.State.Alert?) -> AppAlertConfiguration {
        switch alertType {
        case .logout:
            return .init(
                title: "로그아웃",
                message: "로그아웃 하시겠습니까?",
                primaryButton: .init(title: "로그아웃", style: .primary, action: { store.send(.view(.confirmLogout)) }),
                secondaryButton: .init(title: "취소", style: .neutral, action: { store.send(.view(.alertDismissed)) })
            )
        case .withdrawal:
            return .init(
                title: "회원 탈퇴",
                message: "30일 뒤 계정이 영구 삭제됩니다. 작성한 게시물과 댓글은 익명으로 남으며, 기간 내 재로그인 시 탈퇴가 취소됩니다.",
                primaryButton: .init(title: "탈퇴하기", style: .destructive, action: { store.send(.view(.confirmWithdrawal)) }),
                secondaryButton: .init(title: "취소", style: .neutral, action: { store.send(.view(.alertDismissed)) })
            )
        case .none:
            // Alert가 보이지 않을 때를 위한 기본값. 내용은 중요하지 않습니다.
            return .init(title: "", message: "", primaryButton: .init(title: "", action: {}), secondaryButton: nil)
        }
    }
}

// MARK: - SwiftUI Preview
import Domain

#Preview("Settings View") {
    SettingsView(
        store: Store(initialState: SettingsFeature.State(authInfo: AuthInfo(accessToken: nil,
                                                                            refreshToken: nil,
                                                                            tempToken: "test-temp-token",
                                                                            isNewUser: true,
                                                                            userInfo: nil))) {
            SettingsFeature()
            // _printChanges()를 붙이면 Preview에서 버튼을 눌렀을 때
            // 어떤 Action이 발생하는지 콘솔에서 확인할 수 있어 유용합니다.
                ._printChanges()
        }
    )
}
