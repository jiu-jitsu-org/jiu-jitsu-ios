//
//  TopHeader.swift
//  DesignSystem
//
//  화면 맨 위 머리줄 — 왼쪽 뒤로가기, 가운데 제목, 오른쪽 글자 버튼(선택).
//

import SwiftUI

/// 화면 맨 위 머리줄.
///
/// 화면마다 따로 그리던 머리줄을 하나로 모아, 오른쪽 '삭제'·'취소' 같은 글자 버튼이
/// 화면마다 색·크기가 달라지지 않게 한다. 오른쪽 글자 버튼은 늘 회색 글자다 —
/// 자주 누르지 않는 동작이라 눈길을 끌지 않게 두고, 되돌릴 수 없는 동작의 빨강은 확인 알림창에서만 쓴다.
///
/// 제목은 양옆 버튼 너비와 상관없이 화면 가운데에 놓는다.
/// 설정·알림 화면의 머리줄(꺾쇠 뒤로가기, 높이 44)은 모양이 달라 이 부품을 쓰지 않는다.
public struct TopHeader: View {

    /// 오른쪽 글자 버튼.
    public struct Action {
        let title: String
        let isEnabled: Bool
        let action: () -> Void

        public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    private enum Metrics {
        static let height: CGFloat = 60
        static let horizontalPadding: CGFloat = 16
        // 양옆 버튼 자리만큼 제목 좌우를 비워, 긴 제목이 버튼 밑으로 들어가지 않게 한다.
        static let titleInset: CGFloat = 48
    }

    private let title: String
    private let onBack: (() -> Void)?
    private let trailing: Action?

    /// - Parameters:
    ///   - onBack: nil 이면 뒤로가기를 숨긴다(되돌아갈 곳이 없는 완료 화면 등).
    ///   - trailing: 오른쪽 글자 버튼. nil 이면 비운다.
    public init(
        title: String,
        onBack: (() -> Void)?,
        trailing: Action? = nil
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
    }

    public var body: some View {
        ZStack {
            Text(title)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
                .lineLimit(1)
                .padding(.horizontal, Metrics.titleInset)

            HStack(spacing: 0) {
                if let onBack {
                    backButton(onBack)
                }
                Spacer(minLength: 0)
                if let trailing {
                    trailingButton(trailing)
                }
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .frame(height: Metrics.height)
    }

    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Assets.Common.Icon.arrowLeft.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.component.header.backButtonIcon)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.component.header.backButtonBackground)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로 가기")
    }

    private func trailingButton(_ item: Action) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .font(Font.pretendard.bodyM)
                .foregroundStyle(
                    item.isEnabled
                        ? Color.component.header.actionText
                        : Color.component.header.actionDisabledText
                )
                .frame(minWidth: 36, minHeight: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }
}

#Preview("머리줄") {
    VStack(spacing: 0) {
        TopHeader(title: "대회 정보 수정", onBack: {}, trailing: .init("삭제") {})
        TopHeader(title: "대회 정보 입력", onBack: {}, trailing: .init("취소") {})
        TopHeader(title: "도장 정보 수정", onBack: {}, trailing: .init("삭제", isEnabled: false) {})
        TopHeader(title: "닉네임 설정", onBack: {})
        TopHeader(title: "완료", onBack: nil)
    }
}
