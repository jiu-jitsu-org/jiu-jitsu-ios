//
//  MyProfileCardComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - BeltWeightCardView

/// 벨트와 체급 정보 카드
///
/// 정보가 있을 때와 없을 때 두 가지 상태를 표시합니다.
public struct BeltWeightCardView: View {
    // MARK: - Properties
    
    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    let weightKg: Double?
    let isWeightHidden: Bool
    
    let onBeltTapped: () -> Void
    let onWeightClassTapped: () -> Void
    let onWeightVisibilityToggleTapped: () -> Void
    let onRegisterTapped: () -> Void
    
    // MARK: - Metrics

    private enum Metrics {
        // 카드 외곽 padding과 filledContent 내부 padding 2곳에서 공유
        static let horizontalPadding: CGFloat = 20
    }

    // MARK: - Computed Properties
    
    private var hasBeltInfo: Bool {
        beltRank != nil
    }
    
    private var hasWeightInfo: Bool {
        weightKg != nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 24) {
            if hasBeltInfo && hasWeightInfo {
                filledContent
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 128)
        .background(Color.component.beltCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 4
        )
        .padding(.horizontal, Metrics.horizontalPadding)
    }
    
    // MARK: - Filled Content
    
    private var filledContent: some View {
        HStack(spacing: 0) {
            // 왼쪽: 벨트 섹션
            BeltSection(
                beltRank: beltRank,
                beltStripe: beltStripe,
                onTapped: onBeltTapped
            )
            .frame(maxWidth: .infinity)
            
            // 중앙: 구분선
            Rectangle()
                .fill(Color.primitive.coolGray.cg75)
                .frame(width: 1, height: 36)
                .padding(.vertical, 24)
            
            // 오른쪽: 체급 섹션
            WeightSection(
                weightKg: weightKg,
                isHidden: isWeightHidden,
                onTapped: onWeightClassTapped,
                onVisibilityToggleTapped: onWeightVisibilityToggleTapped
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, Metrics.horizontalPadding)
    }
    
    // MARK: - Empty Content
    
    private var emptyContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                // 아이콘 영역
                HStack(spacing: 5) {
                    // 벨트 아이콘
                    VStack {
                        Assets.MyProfile.Icon.beltBlue.swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 13)
                    .rotationEffect(.degrees(-6.8))
                    
                    // 체급 아이콘
                    VStack {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("??")
                                .font(Font.pretendard.title2)
                                .foregroundStyle(Color.primitive.coolGray.cg700)
                            
                            Text("kg")
                                .font(Font.pretendard.bodyS)
                                .foregroundStyle(Color.primitive.coolGray.cg400)
                        }
                    }
                    .frame(width: 55, height: 42)
                    .background(Color.primitive.coolGray.cg25)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 5)
                    .rotationEffect(.degrees(10.49))
                }
                .frame(height: 56)
                
                // 안내 텍스트
                Text("벨트와 체급이 어떻게 되세요?")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.beltCard.default.text)
            }
            .padding(.top, 24)
            
            // 등록 버튼
            Button {
                onRegisterTapped()
            } label: {
                AppButtonConfiguration(title: "벨트/체급 등록하기", size: .medium)
            }
            .appButtonStyle(.primary, size: .medium, height: 38)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - BeltSection

/// 벨트 정보 섹션
private struct BeltSection: View {
    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    let onTapped: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("벨트")
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.beltCard.filled.labelText)
                .frame(height: 14, alignment: .center)

            if let beltRank = beltRank {
                // 벨트 아이콘
                beltRank.beltIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // 벨트명 + 띠
                if let beltStripe = beltStripe {
                    HStack(alignment: .center, spacing: 5) {
                        Text(beltRank.displayName)
                            .font(Font.pretendard.bodyS)
                            .foregroundStyle(Color.component.beltCard.filled.contentText)

                        Text(beltStripe.displayName)
                            .font(Font.pretendard.bodyS)
                            .foregroundStyle(Color.component.beltCard.filled.contentText)
                    }
                    .frame(height: 18)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }
}

// MARK: - WeightSection

/// 체급 정보 섹션
private struct WeightSection: View {
    let weightKg: Double?
    let isHidden: Bool
    let onTapped: () -> Void
    let onVisibilityToggleTapped: () -> Void
    
    private enum Metrics {
        static let weightHeight: CGFloat = 40
        static let toggleButtonHeight: CGFloat = 22
        static let toggleButtonPadding: CGFloat = 12
        static let weightFontSize: CGFloat = 24
        static let innerSpacing: CGFloat = 4
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("체급")
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.beltCard.filled.labelText)
                .frame(height: 14, alignment: .center)
            
            if let weightKg = weightKg {
                if isHidden {
                    // 숨김 상태
                    VStack(alignment: .center, spacing: Metrics.innerSpacing) {
                        Text("숨김")
                            .font(Font.pretendard.custom(weight: .medium, size: Metrics.weightFontSize))
                            .foregroundStyle(Color.component.beltCard.filled.contentText)
                            .frame(height: Metrics.weightHeight, alignment: .center)
                        
                        Button(action: onVisibilityToggleTapped) {
                            AppButtonConfiguration(title: "보기", size: .small)
                        }
                        .appButtonStyle(.neutral, size: .small, height: Metrics.toggleButtonHeight, horizontalPadding: Metrics.toggleButtonPadding)
                    }
                } else {
                    // 표시 상태
                    VStack(spacing: Metrics.innerSpacing) {
                        Text(String(format: "%.1fkg", weightKg))
                            .font(Font.pretendard.custom(weight: .medium, size: Metrics.weightFontSize))
                            .foregroundStyle(Color.component.beltCard.filled.contentText)
                            .frame(height: Metrics.weightHeight, alignment: .center)
                        
                        Button(action: onVisibilityToggleTapped) {
                            AppButtonConfiguration(title: "숨기기", size: .small)
                        }
                        .appButtonStyle(.neutral, size: .small, height: Metrics.toggleButtonHeight, horizontalPadding: Metrics.toggleButtonPadding)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
    }
}

// MARK: - Preview

#Preview("BeltWeightCardView - 정보 있음") {
    BeltWeightCardView(
        beltRank: .blue,
        beltStripe: .two,
        weightKg: 75.0,
        isWeightHidden: false,
        onBeltTapped: { },
        onWeightClassTapped: { },
        onWeightVisibilityToggleTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltWeightCardView - 정보 없음") {
    BeltWeightCardView(
        beltRank: nil,
        beltStripe: nil,
        weightKg: nil,
        isWeightHidden: false,
        onBeltTapped: { },
        onWeightClassTapped: { },
        onWeightVisibilityToggleTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltWeightCardView - 체급 숨김") {
    BeltWeightCardView(
        beltRank: .purple,
        beltStripe: .four,
        weightKg: 68.5,
        isWeightHidden: true,
        onBeltTapped: { },
        onWeightClassTapped: { },
        onWeightVisibilityToggleTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltWeightCardView - 인터랙티브") {
    struct InteractivePreview: View {
        @State private var isWeightHidden = false
        
        var body: some View {
            BeltWeightCardView(
                beltRank: .black,
                beltStripe: Optional.none,
                weightKg: 82.3,
                isWeightHidden: isWeightHidden,
                onBeltTapped: { },
                onWeightClassTapped: { },
                onWeightVisibilityToggleTapped: {
                    withAnimation {
                        isWeightHidden.toggle()
                    }
                },
                onRegisterTapped: { }
            )
            .background(Color.component.background.default)
        }
    }
    
    return InteractivePreview()
}
