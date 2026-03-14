//
//  NoneStyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem

/// "없음" 스타일 카드 컴포넌트
///
/// 스타일 선택을 해제할 수 있는 카드입니다.
/// 선택 여부에 따라 크기가 변경됩니다.
struct NoneStyleCard: View {
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
            // 배경 색상 - 고정된 회색
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: "#4F535B"))
            
            // "없음" 타이틀을 상단에 배치 - 중앙 정렬
            Text("없음")
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

#Preview("NoneStyleCard - Selected") {
    NoneStyleCard(isSelected: true)
        .padding()
        .background(Color.component.background.default)
}

#Preview("NoneStyleCard - Unselected") {
    NoneStyleCard(isSelected: false)
        .padding()
        .background(Color.component.background.default)
}

#Preview("NoneStyleCard - Comparison") {
    HStack(spacing: 20) {
        VStack {
            Text("선택됨")
                .font(.pretendard.bodyS)
            NoneStyleCard(isSelected: true)
        }
        
        VStack {
            Text("선택 안됨")
                .font(.pretendard.bodyS)
            NoneStyleCard(isSelected: false)
        }
    }
    .padding()
    .background(Color.component.background.default)
}
