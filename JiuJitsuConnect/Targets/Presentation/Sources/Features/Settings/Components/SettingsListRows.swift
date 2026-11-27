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
    static let pressedCornerRadius: CGFloat = 10
    static let pressedHorizontalInset: CGFloat = 8
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
        // 행 전체(라벨·빈 곳 포함)가 눌림 영역이다 (#112)
        Button(action: action) {
            HStack {
                SettingsRowContent(asset: asset, text: text)
                Spacer()
                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                    .frame(width: 34, height: 34)
            }
            .frame(minHeight: SettingsListMetrics.rowHeight)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }
}

// MARK: - Version Row (#326)
/// 버전 정보 줄. 새 버전이 있으면 줄 전체가 스토어로 가는 버튼이 되고, 버전 옆에 작은 '업데이트' 표시를 단다.
/// 다른 줄과 같은 높이 · 글자 크기 안에 들어가게 버전 글자(captionM)와 같은 크기의 회색 캡슐로 둔다 —
/// 파란 채움 버튼(32)은 40 높이 줄에 꽉 차 다른 줄보다 무거워 보였다.
struct SettingsVersionRow: View {
    let asset: ImageAsset
    let version: String
    let isUpdateAvailable: Bool
    let onUpdate: () -> Void

    var body: some View {
        if isUpdateAvailable {
            Button(action: onUpdate) {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(SettingsRowButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("버전 정보 \(version), 새 버전이 있어요")
            .accessibilityHint("앱 스토어에서 업데이트해요")
            .accessibilityAddTraits(.isButton)
        } else {
            content
                .accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        HStack(spacing: 8) {
            SettingsRowContent(asset: asset, text: "버전 정보")
            Spacer()
            Text(version)
                .font(Font.pretendard.captionM)
                .foregroundStyle(Color.component.list.setting.valueText)
            if isUpdateAvailable {
                Text("업데이트")
                    .font(Font.pretendard.captionM)
                    .foregroundStyle(Color.component.button.neutral.defaultText)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Capsule().fill(Color.component.button.neutral.defaultBg))
            }
        }
        .frame(minHeight: SettingsListMetrics.rowHeight)
        .padding(.horizontal, 16)
    }
}

/// 터치 다운 동안에만 행 전체에 눌림 배경을 노출하는 버튼 스타일
private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: SettingsListMetrics.pressedCornerRadius)
                    .fill(
                        configuration.isPressed
                            ? Color.component.list.setting.pressedBackground
                            : Color.clear
                    )
                    .padding(.horizontal, SettingsListMetrics.pressedHorizontalInset)
            )
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
            // 스위치가 행 제목으로 읽히므로 같은 글을 두 번 읽지 않게 숨긴다(부제는 힌트로).
            // 로딩 중에는 스위치 대신 라벨 없는 자리표시라 글을 그대로 읽게 둔다.
            .accessibilityHidden(!isLoading)

            Spacer()

            // 네이티브 Toggle은 .redacted로 on/off 노브가 가려지지 않으므로,
            // 로딩 중에는 Toggle 대신 캡슐 플레이스홀더로 치환한다.
            if isLoading {
                Capsule()
                    .fill(Color.semantic.surface.disabled)
                    .frame(width: Self.toggleSize.width, height: Self.toggleSize.height)
            } else {
                // VoiceOver가 이름 없는 스위치로 읽지 않게 행 제목을 라벨로 준다(화면에는 숨김)
                Toggle(text, isOn: $isOn)
                    .labelsHidden()
                    .accessibilityHint(subtitle ?? "")
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
