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

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onInstructorVerificationTapped()
            } label: {
                Text("관장 사범 인증")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.text)
                    .frame(width: 140, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color.component.list.setting.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Preview

#Preview("MyProfileMoreMenuView") {
    MyProfileMoreMenuView(onInstructorVerificationTapped: { })
        .padding()
        .background(Color.component.background.default)
}
