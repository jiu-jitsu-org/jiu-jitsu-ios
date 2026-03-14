//
//  EmptySelectionCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem

/// 스타일 선택 전 기본 상태 카드
///
/// 사용자가 아직 스타일을 선택하지 않았을 때 표시되는 큰 카드입니다.
/// "+" 아이콘과 "선택하기" 텍스트를 표시합니다.
struct EmptySelectionCard: View {
    let onTap: () -> Void
    
    // MARK: - Metrics
    
    private enum Metrics {
        static let width: CGFloat = 262
        static let height: CGFloat = 394
        static let cornerRadius: CGFloat = 40
        static let borderWidth: CGFloat = 2
        static let dashPattern: [CGFloat] = [8, 8]
        
        static let iconFontSize: CGFloat = 80
        static let titleFontSize: CGFloat = 20
        static let titleHeight: CGFloat = 27
        static let titleTopOffset: CGFloat = -5
        static let contentOffsetY: CGFloat = -13.5
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 배경 - 점선 테두리와 어두운 배경
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .fill(Color.primitive.coolGray.cg900)
            
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .strokeBorder(
                    style: StrokeStyle(
                        lineWidth: Metrics.borderWidth,
                        dash: Metrics.dashPattern
                    )
                )
                .foregroundColor(Color.primitive.coolGray.cg200)
            
            // + 아이콘을 중앙에 배치
            VStack(spacing: 0) {
                // + 아이콘 (배경 원 없이)
                Text("+")
                    .font(Font.cookieRun.custom(weight: .black, size: Metrics.iconFontSize))
                    .foregroundColor(Color.primitive.coolGray.cg100)
                
                // "선택하기" 텍스트
                Text("선택하기")
                    .font(Font.cookieRun.custom(weight: .black, size: Metrics.titleFontSize))
                    .foregroundColor(Color.primitive.coolGray.cg100)
                    .frame(height: Metrics.titleHeight)
                    .padding(.top, Metrics.titleTopOffset)
            }
            .offset(y: Metrics.contentOffsetY)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .cornerRadius(Metrics.cornerRadius)
    }
}

// MARK: - Preview

#Preview("EmptySelectionCard - Default") {
    EmptySelectionCard(onTap: {})
        .padding()
        .background(Color.component.background.default)
}

#Preview("EmptySelectionCard - Interactive") {
    struct InteractivePreview: View {
        @State private var tapCount = 0
        
        var body: some View {
            VStack(spacing: 20) {
                Text("탭 횟수: \(tapCount)")
                    .font(.pretendard.bodyM)
                
                EmptySelectionCard {
                    tapCount += 1
                }
                .onTapGesture {
                    tapCount += 1
                }
            }
            .padding()
            .background(Color.component.background.default)
        }
    }
    
    return InteractivePreview()
}

#Preview("EmptySelectionCard - In Context") {
    // 실제 화면에서 어떻게 보이는지
    ZStack {
        Color.component.background.default
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("스타일 선택")
                .font(.pretendard.display1)
            
            EmptySelectionCard(onTap: {})
            
            Text("위 카드를 탭하여 스타일을 선택하세요")
                .font(.pretendard.bodyS)
                .foregroundColor(.primitive.coolGray.cg500)
        }
        .padding()
    }
}
