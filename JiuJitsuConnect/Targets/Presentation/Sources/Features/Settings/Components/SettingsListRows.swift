//
//  SettingsListRows.swift
//  Presentation
//
//  설정 / 알림 등 설정 계열 화면에서 공통으로 쓰는 리스트 셀 컴포넌트.
//

import SwiftUI
import DesignSystem

enum SettingsListMetrics {
    static let sectionCornerRadius: CGFloat = 16
    static let sectionVerticalPadding: CGFloat = 8
    static let rowSpacing: CGFloat = 4
    static let rowHeight: CGFloat = 40
}

// MARK: - Section Container
struct SettingsSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: SettingsListMetrics.rowSpacing) {
            content
        }
        .padding(.vertical, SettingsListMetrics.sectionVerticalPadding)
        .background(Color.component.list.setting.background)
        .clipShape(RoundedRectangle(cornerRadius: SettingsListMetrics.sectionCornerRadius))
    }
}

// MARK: - Row Content
struct SettingsRowContent: View {
    let asset: ImageAsset
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            asset.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.component.list.setting.leadingIcon)
            Text(text)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.text)
        }
    }
}

// MARK: - Interactive Row (chevron + tap)
struct SettingsInteractiveRow: View {
    let asset: ImageAsset
    let text: String
    let action: () -> Void

    var body: some View {
        HStack {
            SettingsRowContent(asset: asset, text: text)
            Spacer()
            Button(action: action) {
                ZStack {
                    Assets.Common.Icon.chevronRight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                }
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: SettingsListMetrics.rowHeight)
        .padding(.leading, 16)
        .padding(.trailing, 8)
    }
}

// MARK: - Toggle Row
struct SettingsToggleRow: View {
    let asset: ImageAsset
    let text: String
    let subtitle: String?
    // 서버 초기값 로드 전에는 스켈레톤으로 표시해 잘못된 토글 상태가 잠깐 노출되는 것을 막는다.
    var isLoading: Bool = false
    @Binding var isOn: Bool

    // 표준 UISwitch 크기 — 로딩 중 캡슐 플레이스홀더가 실제 토글과 동일한 자리를 차지하게 한다.
    private static let toggleSize = CGSize(width: 51, height: 31)

    var body: some View {
        HStack(spacing: 8) {
            asset.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.component.list.setting.leadingIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.text)
                if let subtitle {
                    Text(subtitle)
                        .font(Font.pretendard.captionM)
                        .foregroundStyle(Color.component.list.setting.subText)
                }
            }

            Spacer()

            // 네이티브 Toggle은 .redacted로 on/off 노브가 가려지지 않으므로,
            // 로딩 중에는 Toggle 대신 캡슐 플레이스홀더로 치환한다.
            if isLoading {
                Capsule()
                    .fill(Color.semantic.surface.disabled)
                    .frame(width: Self.toggleSize.width, height: Self.toggleSize.height)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Color.component.switch.on.bg)
            }
        }
        .frame(minHeight: SettingsListMetrics.rowHeight)
        .padding(.horizontal, 16)
        .padding(.vertical, subtitle == nil ? 0 : 6)
        .redacted(reason: isLoading ? .placeholder : [])
        .disabled(isLoading)
    }
}
