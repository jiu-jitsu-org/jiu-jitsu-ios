//
//  MyProfileCommunityActivityRow.swift
//  Presentation
//
//  Created by suni on 10/20/26.
//

import SwiftUI
import DesignSystem

// MARK: - MyProfileCommunityActivityRow

/// 벨트·체급 카드 아래 '커뮤니티 활동' 진입 줄 (#44)
/// 대회 정보 빈 줄(`EmptyCompetitionView`)과 같은 모양에서 왼쪽 메달 아이콘만 뺐다.
public struct MyProfileCommunityActivityRow: View {
    let onTapped: () -> Void

    private enum Metrics {
        static let height: CGFloat = 56
        static let horizontalPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 18
        static let iconSize: CGFloat = 18
    }

    public var body: some View {
        Button {
            onTapped()
        } label: {
            HStack(spacing: 8) {
                Text("커뮤니티 활동")
                    .font(.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.text)

                Spacer()

                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(Color.component.list.setting.icon)
            }
            .frame(height: Metrics.height)
            .padding(.horizontal, Metrics.horizontalPadding)
            .background(Color.component.list.setting.background)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            // 줄 전체가 누르는 영역
            .contentShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MyProfileCommunityActivityRow(onTapped: { })
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .background(Color.component.background.default)
}
