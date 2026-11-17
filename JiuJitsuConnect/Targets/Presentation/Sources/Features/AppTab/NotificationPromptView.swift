//
//  NotificationPromptView.swift
//  Presentation
//

import SwiftUI
import DesignSystem

/// 첫 글 · 댓글을 올린 뒤 알림 권한을 묻기 전 한 줄 안내(#333) — 알림 받기 / 나중에
///
/// 시스템 권한 창은 [알림 받기]를 눌렀을 때만 띄운다. 처음 연 사람이 어떤 알림이 오는지 모른 채 거절하지 않게 한다.
struct NotificationPromptView: View {

    /// 바텀 시트 detent 높이 (safe area 미포함)
    /// 24(handle) + 12 + 32(아이콘) + 12 + 76(제목·설명) + 20 + 51+4+44+4(CTA 두 개) = 279
    static let contentHeight: CGFloat = 279

    let onAllow: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.component.bottomSheet.selected.container.handle)
                .frame(width: 48, height: 4)
                .frame(maxWidth: .infinity)
                .frame(height: 24)

            Assets.Common.Icon.bell.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.semantic.interactive.primary)
                .padding(.vertical, 12)

            VStack(spacing: 4) {
                Text("댓글이나 좋아요가 달리면 알려 드릴까요?")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                Text("내 글 · 댓글에 댓글 · 답글 · 좋아요가 달리면\n알림으로 알려 드려요.")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, 20)

            VStack(spacing: 4) {
                CTAButton(title: "알림 받기", action: onAllow)
                CTAButton(title: "나중에", type: .text, height: 44, action: onLater)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
    }
}

// MARK: - Preview

#Preview {
    NotificationPromptView(onAllow: {}, onLater: {})
}
