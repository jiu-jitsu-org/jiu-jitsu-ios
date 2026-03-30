//
//  MyProfileStyleComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - MyProfileStyleSectionView

/// 스타일 섹션 (포지션 + 기술 + 서브미션)
public struct MyProfileStyleSectionView: View {
    let bestPosition: (any StyleSelectable)?
    let favoritePosition: (any StyleSelectable)?
    let bestTechnique: (any StyleSelectable)?
    let favoriteTechnique: (any StyleSelectable)?
    let bestSubmission: (any StyleSelectable)?
    let favoriteSubmission: (any StyleSelectable)?
    
    let onRegisterStyleTapped: () -> Void
    
    private enum Metrics {
        static let sectionSpacing: CGFloat = 36
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
            // 포지션 섹션
            StyleCategorySection(
                title: "포지션",
                bestStyle: bestPosition,
                favoriteStyle: favoritePosition,
                onCardTapped: onRegisterStyleTapped
            )
            
            // 기술 섹션
            StyleCategorySection(
                title: "기술",
                bestStyle: bestTechnique,
                favoriteStyle: favoriteTechnique,
                onCardTapped: onRegisterStyleTapped
            )
            
            // 서브미션 섹션
            StyleCategorySection(
                title: "서브미션",
                bestStyle: bestSubmission,
                favoriteStyle: favoriteSubmission,
                onCardTapped: onRegisterStyleTapped
            )
        }
    }
}

// MARK: - StyleCategorySection

/// 개별 스타일 카테고리 섹션 (포지션/기술/서브미션)
private struct StyleCategorySection: View {
    let title: String
    let bestStyle: (any StyleSelectable)?
    let favoriteStyle: (any StyleSelectable)?
    let onCardTapped: () -> Void
    
    private enum Metrics {
        static let titleBottomPadding: CGFloat = 8
        static let cardSpacing: CGFloat = 8
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.titleBottomPadding) {
            // 섹션 타이틀
            Text(title)
                .font(.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)
            
            // 카드 그리드 (2열)
            HStack(spacing: Metrics.cardSpacing) {
                // 왼쪽: 특기 카드
                if let bestStyle = bestStyle {
                    FilledStyleCardItem(label: "특기", style: bestStyle, onTapped: onCardTapped)
                } else {
                    EmptyStyleCardItem(label: "특기", onTapped: onCardTapped)
                }
                
                // 오른쪽: 최애 카드
                if let favoriteStyle = favoriteStyle {
                    FilledStyleCardItem(label: "최애", style: favoriteStyle, onTapped: onCardTapped)
                } else {
                    EmptyStyleCardItem(label: "최애", onTapped: onCardTapped)
                }
            }
        }
    }
}

// MARK: - FilledStyleCardItem

/// 스타일 정보가 있는 카드 아이템
private struct FilledStyleCardItem: View {
    let label: String
    let style: any StyleSelectable
    let onTapped: () -> Void
    
    private enum Metrics {
        static let padding: CGFloat = 16
        static let contentSpacing: CGFloat = 16
        static let iconSize: CGFloat = 40
        static let labelTitleSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 18
    }
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
                // 아이콘
                style.iconImage.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                
                VStack(alignment: .leading, spacing: Metrics.labelTitleSpacing) {
                    // 라벨 (특기/최애)
                    Text(label)
                        .font(Font.pretendard.labelM)
                        .foregroundStyle(Color.component.skillCard.default.labelText)
                    
                    // 스타일 이름
                    Text(style.tabTitle)
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.skillCard.default.titleTextFilled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Metrics.padding)
            .background(Color.component.skillCard.default.bg)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyStyleCardItem

/// 스타일 정보가 없는 빈 카드 아이템
private struct EmptyStyleCardItem: View {
    let label: String
    let onTapped: () -> Void
    
    private enum Metrics {
        static let padding: CGFloat = 16
        static let contentSpacing: CGFloat = 16
        static let iconSize: CGFloat = 40
        static let iconCornerRadius: CGFloat = 14
        static let labelTitleSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 18
    }
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
                // 빈 아이콘 배경
                RoundedRectangle(cornerRadius: Metrics.iconCornerRadius)
                    .fill(Color.primitive.coolGray.cg50)
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                
                VStack(alignment: .leading, spacing: Metrics.labelTitleSpacing) {
                    // 라벨 (특기/최애)
                    Text(label)
                        .font(Font.pretendard.labelM)
                        .foregroundStyle(Color.component.skillCard.default.labelText)
                    
                    // 안내 텍스트
                    Text("지정해주세요")
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.skillCard.default.titleTextEmpty)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Metrics.padding)
            .background(Color.component.skillCard.default.bg)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyStyleView

/// 스타일 정보가 전혀 없을 때 표시되는 뷰
public struct EmptyStyleView: View {
    let onRegisterStyleTapped: () -> Void
    
    private enum Metrics {
        static let titleBottomPadding: CGFloat = 8
        static let buttonTopPadding: CGFloat = 24
        static let buttonHeight: CGFloat = 38
        static let decorativeCardsTopPadding: CGFloat = 16
        static let decorativeCardsHeight: CGFloat = 282
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Text("나의 주짓수를 보여주세요")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)
                .padding(.bottom, Metrics.titleBottomPadding)

            Text("특기와 최애 포지션, 기술 등을 등록해보세요.")
                .font(Font.pretendard.bodyM)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
            
            Button {
                onRegisterStyleTapped()
            } label: {
                AppButtonConfiguration(title: "내 스타일 등록하기", size: .medium)
            }
            .appButtonStyle(.tint, size: .medium, height: Metrics.buttonHeight)
            .padding(.top, Metrics.buttonTopPadding)
            
            DecorativeCardsView()
                .padding(.top, Metrics.decorativeCardsTopPadding)
        }
    }
}

// MARK: - DecorativeCardsView

/// 장식용 스타일 카드 배치 뷰
private struct DecorativeCardsView: View {
    private enum Metrics {
        static let height: CGFloat = 282
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            
            ZStack(alignment: .top) {
                decorativeCard(config: .guardPosition, centerX: centerX)
                decorativeCard(config: .topPosition, centerX: centerX)
                decorativeCard(config: .armLock, centerX: centerX)
                decorativeCard(config: .escapeDefense, centerX: centerX)
            }
        }
        .frame(height: Metrics.height)
    }
    
    private func decorativeCard(config: DecorativeCardConfig, centerX: CGFloat) -> some View {
        config.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: config.width, height: config.height)
            .rotationEffect(.degrees(config.rotationDegrees))
            .position(
                x: centerX + config.xPosition + config.width / 2,
                y: config.yPosition + config.height / 2
            )
            .zIndex(config.zIndex)
    }
}

// MARK: - DecorativeCardConfig

/// 장식용 카드 설정
private struct DecorativeCardConfig {
    let image: Image
    let width: CGFloat
    let height: CGFloat
    let xPosition: CGFloat
    let yPosition: CGFloat
    let rotationDegrees: Double
    let zIndex: Double
    
    static let guardPosition = DecorativeCardConfig(
        image: Assets.MyProfile.Card.styleGuardPosition.swiftUIImage,
        width: 151.09,
        height: 117.58,
        xPosition: -2.49,
        yPosition: 26,
        rotationDegrees: 16.33,
        zIndex: 3
    )
    
    static let topPosition = DecorativeCardConfig(
        image: Assets.MyProfile.Card.styleTopPosition.swiftUIImage,
        width: 142,
        height: 110.51,
        xPosition: -152.36,
        yPosition: 59,
        rotationDegrees: -16.18,
        zIndex: 0
    )
    
    static let armLock = DecorativeCardConfig(
        image: Assets.MyProfile.Card.styleArmLock.swiftUIImage,
        width: 153.67,
        height: 119.6,
        xPosition: -33.49,
        yPosition: 110,
        rotationDegrees: -11.04,
        zIndex: 2
    )
    
    static let escapeDefense = DecorativeCardConfig(
        image: Assets.MyProfile.Card.styleEscapeDefense.swiftUIImage,
        width: 132.43,
        height: 103.09,
        xPosition: -109.64,
        yPosition: 163.46,
        rotationDegrees: 5.83,
        zIndex: 1
    )
}

// MARK: - Preview

#Preview("MyProfileStyleSectionView - 정보 있음") {
    MyProfileStyleSectionView(
        bestPosition: PositionType.top,
        favoritePosition: PositionType.guard,
        bestTechnique: TechniqueType.sweeps,
        favoriteTechnique: TechniqueType.escapes,
        bestSubmission: SubmissionType.chokes,
        favoriteSubmission: SubmissionType.armLocks,
        onRegisterStyleTapped: { print("스타일 등록") }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileStyleSectionView - 일부 정보만") {
    MyProfileStyleSectionView(
        bestPosition: PositionType.top,
        favoritePosition: nil,
        bestTechnique: nil,
        favoriteTechnique: TechniqueType.escapes,
        bestSubmission: SubmissionType.chokes,
        favoriteSubmission: nil,
        onRegisterStyleTapped: { print("스타일 등록") }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("EmptyStyleView") {
    EmptyStyleView(
        onRegisterStyleTapped: { print("스타일 등록") }
    )
    .padding()
    .background(Color.component.background.default)
}
