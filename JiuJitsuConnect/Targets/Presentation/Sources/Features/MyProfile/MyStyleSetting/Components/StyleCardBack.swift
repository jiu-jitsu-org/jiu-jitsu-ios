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
/// 메인 화면에 표시되는 큰 스타일 카드의 뒷면입니다.
/// 내 띠 색 바탕(띠가 없으면 회색)에 앱 로고와 스타일 이름을 표시합니다.
struct StyleCardBack: View {
    let style: any StyleSelectable
    /// 바탕을 칠할 띠. 없으면 회색.
    var beltRank: BeltRank? = nil

    // MARK: - Colors

    /// 띠 색 바탕. 흰띠는 페이지 바탕 위에서 뜨게 순백.
    private var backgroundColor: Color {
        beltRank?.beltSurfaceColor ?? Color.primitive.coolGray.cg75
    }

    /// 로고·이름 색 — 밝은 띠는 어둡게, 띠가 없으면 회색 글자, 그 외 흰색
    private var foregroundColor: Color {
        guard let beltRank else { return Color.primitive.coolGray.cg600 }
        return beltRank.isLightBelt ? Color.component.myBelt.onLight : .white
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(backgroundColor)

            VStack(alignment: .center, spacing: 24) {
                // 앱 로고 (흰 글자 로고를 바탕에 맞는 색으로 칠한다)
                Assets.Splash.logo.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 136)

                // 스타일 이름
                Text(style.fullTitle)
                    .font(.pretendard.display1)
                    .lineSpacing(5)
            }
            .foregroundStyle(foregroundColor)
        }
        .frame(width: 262, height: 394)
    }
}

// MARK: - Preview

#Preview("StyleCardBack - Position Top") {
    StyleCardBack(
        style: PositionType.top
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Position Guard") {
    StyleCardBack(
        style: PositionType.guard
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission ArmLocks") {
    StyleCardBack(
        style: SubmissionType.armLocks
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission Chokes") {
    StyleCardBack(
        style: SubmissionType.chokes
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission LegLocks") {
    StyleCardBack(
        style: SubmissionType.legLocks
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Takedowns") {
    StyleCardBack(
        style: TechniqueType.takedowns
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Sweeps") {
    StyleCardBack(
        style: TechniqueType.sweeps
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Escapes") {
    StyleCardBack(
        style: TechniqueType.escapes
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique GuardPasses") {
    StyleCardBack(
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
            StyleCardBack(style: PositionType.top)
            StyleCardBack(style: PositionType.guard)
        }
        
        Text("서브미션 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(style: SubmissionType.armLocks)
            StyleCardBack(style: SubmissionType.chokes)
        }
        
        Text("기술 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(style: TechniqueType.takedowns)
            StyleCardBack(style: TechniqueType.sweeps)
        }
    }
    .padding()
    .background(Color.component.background.default)
}
