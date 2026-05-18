//
//  MyProfileMoreMenuView.swift
//  Presentation
//
//  Created by suni on 5/18/26.
//

import SwiftUI
import DesignSystem

// MARK: - MyProfileMoreMenuView

/// MY 탭 우측 상단 "..." 버튼에 노출되는 메뉴 팝업
///
/// 현재는 "관장 사범 인증" 단일 항목만 노출된다.
/// 외부 영역 탭으로 dismiss하는 동작은 호출부에서 처리한다.
struct MyProfileMoreMenuView: View {
    let onInstructorVerificationTapped: () -> Void

    private enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let shadowOffsetY: CGFloat = 2
        static let shadowOpacity: Double = 0.12
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onInstructorVerificationTapped()
            } label: {
                Text("관장 사범 인증")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.text)
                    .padding(.horizontal, Metrics.horizontalPadding)
                    .padding(.vertical, Metrics.verticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color.component.list.setting.background)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .shadow(
            color: Color.black.opacity(Metrics.shadowOpacity),
            radius: Metrics.shadowRadius,
            x: 0,
            y: Metrics.shadowOffsetY
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Preview

#Preview("MyProfileMoreMenuView") {
    MyProfileMoreMenuView(onInstructorVerificationTapped: { })
        .padding()
        .background(Color.component.background.default)
}
