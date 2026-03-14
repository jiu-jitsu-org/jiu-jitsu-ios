//
//  SmallStyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 스타일 미리보기용 작은 카드 컴포넌트
///
/// 하단 스크롤 영역에 표시되는 작은 스타일 카드입니다.
/// 선택 여부에 따라 크기가 변경됩니다.
struct SmallStyleCard: View {
    let style: any StyleSelectable
    let label: String
    let isSelected: Bool
    
    // MARK: - Metrics
    
    private enum Metrics {
        enum Size {
            static let selectedWidth: CGFloat = 73.53
            static let selectedHeight: CGFloat = 88
            static let unselectedWidth: CGFloat = 55
            static let unselectedHeight: CGFloat = 65
        }
        
        enum CornerRadius {
            static let selected: CGFloat = 19.29
            static let unselected: CGFloat = 14.4
        }
        
        enum Font {
            static let size: CGFloat = 16
        }
        
        enum Padding {
            static let selectedTop: CGFloat = 20
            static let unselectedTop: CGFloat = 14.7
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardWidth: CGFloat {
        isSelected ? Metrics.Size.selectedWidth : Metrics.Size.unselectedWidth
    }
    
    private var cardHeight: CGFloat {
        isSelected ? Metrics.Size.selectedHeight : Metrics.Size.unselectedHeight
    }
    
    private var cornerRadius: CGFloat {
        isSelected ? Metrics.CornerRadius.selected : Metrics.CornerRadius.unselected
    }
    
    private var topPadding: CGFloat {
        isSelected ? Metrics.Padding.selectedTop : Metrics.Padding.unselectedTop
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // 배경 색상 - style마다 다른 색상 사용
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: style.smallCardColorHex))
            
            // 짧은 타이틀을 상단에 배치 - 중앙 정렬
            Text(style.shortTitle)
                .font(.cookieRun.custom(weight: .black, size: Metrics.Font.size))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, topPadding)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: topPadding)
        }
        .frame(width: cardWidth, height: cardHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview("SmallStyleCard - Position Styles") {
    HStack(spacing: 8) {
        // 탑 포지션 - 선택됨
        SmallStyleCard(
            style: PositionType.top,
            label: "탑",
            isSelected: true
        )
        
        // 가드 포지션 - 선택 안됨
        SmallStyleCard(
            style: PositionType.guard,
            label: "가드",
            isSelected: false
        )
    }
    .padding()
    .background(Color.component.background.default)
}

#Preview("SmallStyleCard - Submission Styles") {
    HStack(spacing: 8) {
        // 팔 관절기 - 선택됨
        SmallStyleCard(
            style: SubmissionType.armLocks,
            label: "팔",
            isSelected: true
        )
        
        // 조르기 - 선택 안됨
        SmallStyleCard(
            style: SubmissionType.chokes,
            label: "조르",
            isSelected: false
        )
        
        // 하체 관절기 - 선택 안됨
        SmallStyleCard(
            style: SubmissionType.legLocks,
            label: "하체",
            isSelected: false
        )
    }
    .padding()
    .background(Color.component.background.default)
}

#Preview("SmallStyleCard - Technique Styles") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            // 테이크다운 - 선택 안됨
            SmallStyleCard(
                style: TechniqueType.takedowns,
                label: "테이",
                isSelected: false
            )
            
            // 스윕 - 선택됨
            SmallStyleCard(
                style: TechniqueType.sweeps,
                label: "스윕",
                isSelected: true
            )
            
            // 이스케이프 - 선택 안됨
            SmallStyleCard(
                style: TechniqueType.escapes,
                label: "이스",
                isSelected: false
            )
            
            // 가드패스 - 선택 안됨
            SmallStyleCard(
                style: TechniqueType.guardPasses,
                label: "패스",
                isSelected: false
            )
        }
        .padding()
    }
    .background(Color.component.background.default)
}

#Preview("SmallStyleCard - Interactive") {
    struct InteractivePreview: View {
        @State private var selectedIndex = 0
        let styles: [any StyleSelectable] = SubmissionType.allCases
        
        var body: some View {
            VStack(spacing: 20) {
                Text("선택된: \(styles[selectedIndex].fullTitle)")
                    .font(.pretendard.bodyM)
                
                HStack(spacing: 8) {
                    ForEach(Array(styles.enumerated()), id: \.offset) { index, style in
                        SmallStyleCard(
                            style: style,
                            label: style.shortTitle,
                            isSelected: selectedIndex == index
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedIndex = index
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.component.background.default)
        }
    }
    
    return InteractivePreview()
}
