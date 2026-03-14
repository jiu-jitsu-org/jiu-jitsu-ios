//
//  StyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 스타일 카드 앞면 컴포넌트
///
/// 메인 화면에 표시되는 큰 스타일 카드의 앞면입니다.
/// 배경 이미지, 아이콘, 타이틀, 설명을 포함합니다.
struct StyleCard: View {
    let style: any StyleSelectable
    let isSelected: Bool
    
    // MARK: - Metrics
    
    private enum Metrics {
        static let cardWidth: CGFloat = 262
        static let cardHeight: CGFloat = 394
        static let cornerRadius: CGFloat = 40
        
        static let iconSize: CGFloat = 93
        static let iconBottomPadding: CGFloat = 54
        
        static let titleFontSize: CGFloat = 40
        static let titleHeight: CGFloat = 54
        static let titleBottomPadding: CGFloat = 20
        
        static let descriptionFontSize: CGFloat = 16
        static let descriptionHeight: CGFloat = 72
        static let descriptionLineSpacing: CGFloat = 4
        static let descriptionHorizontalPadding: CGFloat = 25
        static let descriptionBottomPadding: CGFloat = 32
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .center) {
            // 배경 이미지 - 카드 크기에 딱 맞게 (비율 무시하고 꽉 채움)
            style.backgroundImage.swiftUIImage
                .resizable()
                .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // 아이콘
                style.iconImage.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .padding(.bottom, Metrics.iconBottomPadding)
                
                // 풀 타이틀
                Text(style.fullTitle)
                    .font(.cookieRun.custom(weight: .black, size: Metrics.titleFontSize))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: Metrics.titleHeight)
                    .padding(.bottom, Metrics.titleBottomPadding)
                
                // 카드 설명
                Text(style.cardDescription)
                    .font(.pretendard.custom(weight: .medium, size: Metrics.descriptionFontSize))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Metrics.descriptionLineSpacing)
                    .frame(height: Metrics.descriptionHeight)
                    .padding(.horizontal, Metrics.descriptionHorizontalPadding)
                    .padding(.bottom, Metrics.descriptionBottomPadding)
            }
        }
        .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
        .cornerRadius(Metrics.cornerRadius)
    }
}

// MARK: - Preview

#Preview("StyleCard - Position Top") {
    StyleCard(
        style: PositionType.top,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Position Guard") {
    StyleCard(
        style: PositionType.guard,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission ArmLocks") {
    StyleCard(
        style: SubmissionType.armLocks,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission Chokes") {
    StyleCard(
        style: SubmissionType.chokes,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission LegLocks") {
    StyleCard(
        style: SubmissionType.legLocks,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Takedowns") {
    StyleCard(
        style: TechniqueType.takedowns,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Sweeps") {
    StyleCard(
        style: TechniqueType.sweeps,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Escapes") {
    StyleCard(
        style: TechniqueType.escapes,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique GuardPasses") {
    StyleCard(
        style: TechniqueType.guardPasses,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Comparison") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Position Styles")
                .font(.pretendard.display1)
            
            HStack(spacing: 20) {
                StyleCard(style: PositionType.top, isSelected: true)
                StyleCard(style: PositionType.guard, isSelected: true)
            }
            
            Text("Submission Styles")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                StyleCard(style: SubmissionType.armLocks, isSelected: true)
                StyleCard(style: SubmissionType.chokes, isSelected: true)
                StyleCard(style: SubmissionType.legLocks, isSelected: true)
            }
            
            Text("Technique Styles")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                StyleCard(style: TechniqueType.takedowns, isSelected: true)
                StyleCard(style: TechniqueType.sweeps, isSelected: true)
                StyleCard(style: TechniqueType.escapes, isSelected: true)
                StyleCard(style: TechniqueType.guardPasses, isSelected: true)
            }
        }
        .padding()
    }
    .background(Color.component.background.default)
}
