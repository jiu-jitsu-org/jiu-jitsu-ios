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
/// 설정 타입과 스타일 이름을 간단하게 표시합니다.
struct StyleCardBack: View {
    let style: any StyleSelectable
    let settingType: MyStyleSettingType
    
    // MARK: - Metrics
    
    private enum Metrics {
        static let cardWidth: CGFloat = 262
        static let cardHeight: CGFloat = 394
        static let cornerRadius: CGFloat = 40
        static let contentSpacing: CGFloat = 7
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 배경 색상 - 고정된 회색
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .fill(Color.primitive.coolGray.cg75)
            
            VStack(alignment: .center, spacing: Metrics.contentSpacing) {
                // 타이틀 - 화면 타입 표시 (포지션/서브미션/기술)
                Text(settingType.navigationTitle)
                    .font(.pretendard.bodyM)
                    .foregroundColor(.primitive.coolGray.cg400)
                
                // 캡션 - 스타일 타이틀
                Text(style.fullTitle)
                    .font(.pretendard.display1)
                    .lineSpacing(5)
                    .foregroundColor(.primitive.coolGray.cg600)
            }
        }
        .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
    }
}

// MARK: - Preview

#Preview("StyleCardBack - Position Top") {
    StyleCardBack(
        style: PositionType.top,
        settingType: .position
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Position Guard") {
    StyleCardBack(
        style: PositionType.guard,
        settingType: .position
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission ArmLocks") {
    StyleCardBack(
        style: SubmissionType.armLocks,
        settingType: .submission
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission Chokes") {
    StyleCardBack(
        style: SubmissionType.chokes,
        settingType: .submission
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Submission LegLocks") {
    StyleCardBack(
        style: SubmissionType.legLocks,
        settingType: .submission
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Takedowns") {
    StyleCardBack(
        style: TechniqueType.takedowns,
        settingType: .technique
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Sweeps") {
    StyleCardBack(
        style: TechniqueType.sweeps,
        settingType: .technique
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique Escapes") {
    StyleCardBack(
        style: TechniqueType.escapes,
        settingType: .technique
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - Technique GuardPasses") {
    StyleCardBack(
        style: TechniqueType.guardPasses,
        settingType: .technique
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCardBack - All Types Comparison") {
    VStack(spacing: 30) {
        Text("포지션 설정")
            .font(.pretendard.display1)
        
        HStack(spacing: 20) {
            StyleCardBack(style: PositionType.top, settingType: .position)
            StyleCardBack(style: PositionType.guard, settingType: .position)
        }
        
        Text("서브미션 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(style: SubmissionType.armLocks, settingType: .submission)
            StyleCardBack(style: SubmissionType.chokes, settingType: .submission)
        }
        
        Text("기술 설정")
            .font(.pretendard.display1)
            .padding(.top, 20)
        
        HStack(spacing: 20) {
            StyleCardBack(style: TechniqueType.takedowns, settingType: .technique)
            StyleCardBack(style: TechniqueType.sweeps, settingType: .technique)
        }
    }
    .padding()
    .background(Color.component.background.default)
}
