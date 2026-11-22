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
                    // 게스트는 푸시 토큰 등록·서버 설정이 없으므로 노출하지 않는다.
                    if !store.authInfo.isGuest {
                        SettingsSection {
                            SettingsInteractiveRow(asset: Assets.Common.Icon.bell, text: "알림") {
                                store.send(.view(.notificationButtonTapped))
                            }
                        }

                        // MARK: - 차단한 회원 (#56) — 웹 화면을 서브뷰로 연다. 비로그인은 미노출
                        SettingsSection {
                            SettingsInteractiveRow(asset: Assets.Common.Icon.userX, text: "차단한 회원") {
                                store.send(.view(.blockedUsersButtonTapped))
                            }
                        }
                    }

                    // MARK: - 공지사항 (#369) — 로그인 여부와 상관없이 보인다. 약관과 같은 웹뷰로 웹 공지 화면을 연다
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.megaphone, text: "공지사항") {
                            store.send(.view(.noticesButtonTapped))
                        }
                    }

                    // MARK: - 약관 및 정책 섹션
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.fileText, text: "서비스 이용 약관") {
                            store.send(.view(.termsButtonTapped))
                        }
                        SettingsInteractiveRow(asset: Assets.Common.Icon.shieldCheck, text: "개인정보 처리 방침") {
                            store.send(.view(.privacyPolicyButtonTapped))
                        }
                        SettingsInteractiveRow(asset: Assets.Common.Icon.mailCheck, text: "마케팅 정보 수신 동의") {
                            store.send(.view(.marketingConsentButtonTapped))
                        }
                        // 이용 통계(#476) — 로그인 여부와 상관없이 보인다. 목록에서 바로 꺼지지 않게 한 단계 아래 화면에서 끈다.
                        SettingsInteractiveRow(asset: Assets.Common.Icon.chartPie, text: "이용 통계") {
                            store.send(.view(.analyticsButtonTapped))
                        }
                    }

                    // MARK: - 문의하기 (#331) — 로그인 여부와 상관없이 보인다
                    if SupportContact.email != nil {
                        SettingsSection {
                            SettingsInteractiveRow(asset: Assets.Common.Icon.headset, text: "문의하기") {
                                store.send(.view(.inquiryButtonTapped))
                            }
                        }
                    }

                    // MARK: - 버전 정보 섹션
                    SettingsSection {
                        HStack(spacing: 8) {
                            SettingsRowContent(asset: Assets.Common.Icon.version, text: "버전 정보")
                            Spacer()
                            versionValue
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
        .toast(
            store.toast,
            onSwipe: { store.send(.internal(.toastDismissed)) },
            onButtonTapped: { store.send(.view(.toastButtonTapped($0))) }
        )
        .onAppear { store.send(.view(.onAppear)) }
        .appAlert(
            isPresented: Binding(
                get: { store.alert != nil },
                set: { if !$0 { store.send(.view(.alertDismissed)) } }
            ),
            configuration: alertConfiguration(for: store.alert)
        )
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .withdrawalGuard(isWithdrawing: store.isWithdrawing)
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.notificationSetting,
                action: \.destination.notificationSetting
            )
        ) { notificationStore in
            NotificationSettingView(store: notificationStore)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.analyticsSetting,
                action: \.destination.analyticsSetting
            )
        ) { analyticsStore in
            AnalyticsSettingView(store: analyticsStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.termsWebCover, action: \.termsWebCover)
        ) { termsStore in
            TermsWebViewView(store: termsStore)
        }
    }

    // MY에서 밀어 여는 화면이 되어(#241) 알림 설정 화면과 같은 모양의 뒤로가기를 둔다.
    private var headerView: some View {
        HStack {
            Button(action: { store.send(.view(.backTapped)) }) {
                Assets.Common.Icon.chevronLeft.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("설정")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)

            Spacer()

            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top))
    }

    // MARK: - 버전 정보 (#326)
    /// 새 버전이 있을 때만 버전 옆에 '업데이트'를 둔다. 최신이거나 확인 못 했으면 버전만 — 최신이라는 문구는 따로 알릴 필요가 없다.
    @ViewBuilder
    private var versionValue: some View {
        Text(store.appVersion)
            .font(Font.pretendard.captionM)
            .foregroundStyle(Color.component.list.setting.valueText)
        if store.isLatestVersion == false {
            Button {
                store.send(.view(.updateButtonTapped))
            } label: {
                AppButtonConfiguration(title: "업데이트", size: .small)
            }
            .appButtonStyle(.primary, size: .small, height: 32)
        }
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
                message: store.isAppleWithdrawal
                    // Apple은 탈퇴 직전 재인증 창이 떠서 미리 알린다(#398). 예고 없이 뜨면 왜 다시 로그인하는지 몰라 닫게 된다.
                    ? "30일 뒤 계정이 영구 삭제됩니다. 작성한 게시물과 댓글은 익명으로 남으며, 기간 내 재로그인 시 탈퇴가 취소됩니다. 확인을 위해 Apple 로그인 창이 한 번 더 열립니다."
                    : "30일 뒤 계정이 영구 삭제됩니다. 작성한 게시물과 댓글은 익명으로 남으며, 기간 내 재로그인 시 탈퇴가 취소됩니다.",
                primaryButton: .init(title: "탈퇴하기", style: .destructive, action: { store.send(.view(.confirmWithdrawal)) }),
                secondaryButton: .init(title: "취소", style: .neutral, action: { store.send(.view(.alertDismissed)) }),
                // 30일 · 익명 · 재로그인 취소 · Apple 확인 창까지 다 읽어야 해 줄 수를 막지 않는다.
                messageLineLimit: nil
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

private extension View {
    /// 탈퇴 요청 중에는 화면이 닫히면 요청이 취소되므로(설정은 MY 스택의 한 화면, #241) 딤으로 조작을 막고 스와이프 백도 막는다.
    func withdrawalGuard(isWithdrawing: Bool) -> some View {
        self
            // MY의 관장 사범 인증 업로드 중 덮개와 같은 모양
            .overlay {
                if isWithdrawing {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                            .tint(.white)
                    }
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isWithdrawing)
            .background {
                if isWithdrawing {
                    InteractivePopBlocker()
                }
            }
    }
}
