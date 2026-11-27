//
//  StyleCardBack.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 스타일 카드 뒷면 컴포넌트
///
/// 설정 화면에 표시되는 큰 스타일 카드의 뒷면입니다.
/// 로고 무늬 회색 바탕에 앱 로고 · 분류(포지션/기술/서브미션) · 스타일 이름을 표시합니다.
struct StyleCardBack: View {
    let category: String
    let style: any StyleSelectable

    // MARK: - Body

    var body: some View {
        ZStack {
            StyleCardBackSurface(cornerRadius: StyleCardMetrics.cornerRadius, borderWidth: 2)

            // 글자 · 로고가 카드에 비해 커 보여 한 단계씩 줄였다(#495)
            VStack(spacing: 0) {
                // 앱 로고 (흰 글자)
                Assets.Splash.logo.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84)
                    .accessibilityHidden(true)

                Text(category)
                    .font(.pretendard.custom(weight: .medium, size: 15))
                    .kerning(0.6)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding(.top, 26)

                // 긴 이름(스윕 · 뒤집기)만 폭에 맞춰 줄인다
                Text(style.fullTitle)
                    .font(.pretendard.custom(weight: .semiBold, size: 26))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }
        }
        .frame(width: 262, height: 394)
    }
}

// MARK: - Preview

#Preview("StyleCardBack - Position Top") {
    StyleCardBack(
        category: "포지션",
        style: PositionType.top
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Position Guard") {
    StyleCardBack(
        category: "포지션",
        style: PositionType.guard
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission ArmLocks") {
    StyleCardBack(
        category: "서브미션",
        style: SubmissionType.armLocks
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission Chokes") {
    StyleCardBack(
        category: "서브미션",
        style: SubmissionType.chokes
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission LegLocks") {
    StyleCardBack(
        category: "서브미션",
        style: SubmissionType.legLocks
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Takedowns") {
    StyleCardBack(
        category: "기술",
        style: TechniqueType.takedowns
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Sweeps") {
    StyleCardBack(
        category: "기술",
        style: TechniqueType.sweeps
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Escapes") {
    StyleCardBack(
        category: "기술",
        style: TechniqueType.escapes
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique GuardPasses") {
    StyleCardBack(
        category: "기술",
        style: TechniqueType.guardPasses
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - All Types Comparison") {
    VStack(spacing: 30) {
        Text("포지션 설정")
            .font(.pretendard.display1)
        
        HStack(spacing: 20) {
            StyleCardBack(category: "포지션", style: PositionType.top)
            StyleCardBack(category: "포지션", style: PositionType.guard)
        }
        
        Text("서브미션 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(category: "서브미션", style: SubmissionType.armLocks)
            StyleCardBack(category: "서브미션", style: SubmissionType.chokes)
        }
        
        Text("기술 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(category: "기술", style: TechniqueType.takedowns)
            StyleCardBack(category: "기술", style: TechniqueType.sweeps)
        }
    }
    .padding()
    .background(Color.component.background.default)
}
