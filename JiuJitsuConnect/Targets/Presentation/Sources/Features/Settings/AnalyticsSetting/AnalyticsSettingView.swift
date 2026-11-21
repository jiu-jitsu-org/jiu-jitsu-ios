//
//  AnalyticsSettingView.swift
//  Presentation
//
//  설정 → 이용 통계 화면(#476).
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

private enum Style {
    static let headerHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 12
    // 설명 글을 섹션 안쪽 글자와 같은 줄에 맞춘다
    static let captionHorizontalPadding: CGFloat = 16
}

public struct AnalyticsSettingView: View {
    @Bindable var store: StoreOf<AnalyticsSettingFeature>

    public init(store: StoreOf<AnalyticsSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(alignment: .leading, spacing: Style.sectionSpacing) {
                    SettingsSection {
                        SettingsToggleRow(
                            asset: Assets.Common.Icon.documents,
                            text: "이용 통계 보내기",
                            subtitle: nil,
                            isOn: Binding(
                                get: { store.isEnabled },
                                set: { store.send(.view(.toggled($0))) }
                            )
                        )
                    }

                    description
                }
                .padding(.horizontal, Style.horizontalPadding)
                .padding(.vertical, Style.verticalPadding)
            }
            .background(Color.component.background.default)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(
            item: $store.scope(state: \.termsWebCover, action: \.termsWebCover)
        ) { termsStore in
            TermsWebViewView(store: termsStore)
        }
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("어떤 화면을 자주 쓰는지 같은 이용 기록을 모아 앱을 더 좋게 만드는 데 써요. 이름이나 연락처는 보내지 않아요.")
            Text("끄면 지금부터 보내지 않고, 앱은 그대로 쓸 수 있어요.")

            Button {
                store.send(.view(.privacyPolicyTapped))
            } label: {
                Text("개인정보 처리 방침 보기")
                    .underline()
                    // 글자 링크라 눌림 영역이 작다 — 높이를 44pt까지 넓힌다
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isLink)
        }
        .font(Font.pretendard.captionM)
        .foregroundStyle(Color.component.list.setting.subText)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Style.captionHorizontalPadding)
    }

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
            .accessibilityLabel("뒤로")

            Spacer()

            Text("이용 통계")
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
}

#Preview("Analytics Setting View") {
    NavigationStack {
        AnalyticsSettingView(
            store: Store(
                initialState: AnalyticsSettingFeature.State(
                    isEnabled: true,
                    privacyPolicyURL: URL(string: "https://example.com/policies/privacy-policy")
                )
            ) {
                AnalyticsSettingFeature()
            }
        )
    }
}
