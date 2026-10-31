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

/// 최애 스타일 섹션 (포지션 · 기술 · 서브미션 최애 한 칸씩)
///
/// 포지션·서브미션은 '기술'에 들지 않아, 셋을 아우르는 이름으로 앱이 이미 쓰는 '스타일'을 쓴다.
///
/// 특기는 자기 평가라 입력 부담이 커서 최애만 보여 준다(#118). 남이 보는 프로필도 같은 모양을 쓴다.
public struct MyProfileStyleSectionView: View {
    let favoritePosition: (any StyleSelectable)?
    let favoriteTechnique: (any StyleSelectable)?
    let favoriteSubmission: (any StyleSelectable)?

    /// 카드를 눌러 수정한다. `nil`이면 읽기 전용(남이 보는 프로필)이라 빈 칸에 고르라는 말 대신 안 골랐다고 적는다.
    let onStyleCardTapped: ((MyStyleSettingType) -> Void)?

    public init(
        favoritePosition: (any StyleSelectable)?,
        favoriteTechnique: (any StyleSelectable)?,
        favoriteSubmission: (any StyleSelectable)?,
        onStyleCardTapped: ((MyStyleSettingType) -> Void)?
    ) {
        self.favoritePosition = favoritePosition
        self.favoriteTechnique = favoriteTechnique
        self.favoriteSubmission = favoriteSubmission
        self.onStyleCardTapped = onStyleCardTapped
    }

    private struct Item {
        let type: MyStyleSettingType
        let style: (any StyleSelectable)?
    }

    private var items: [Item] {
        [
            Item(type: .position, style: favoritePosition),
            Item(type: .technique, style: favoriteTechnique),
            Item(type: .submission, style: favoriteSubmission)
        ]
    }

    private func tapAction(for type: MyStyleSettingType) -> (() -> Void)? {
        guard let onStyleCardTapped else { return nil }
        return { onStyleCardTapped(type) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("최애 스타일")
                .font(.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)

            HStack(alignment: .top, spacing: 8) {
                ForEach(items, id: \.type.title) { item in
                    FavoriteStyleCardItem(
                        category: item.type.title,
                        style: item.style,
                        emptyText: onStyleCardTapped == nil ? "아직 안 골랐어요" : "지정해주세요",
                        onTapped: tapAction(for: item.type)
                    )
                }
            }
            // 이름이 두 줄로 넘어가는 칸이 있어도 세 칸 높이를 맞춘다
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - FavoriteStyleCardItem

/// 최애 한 칸 — 아이콘 · 분류(포지션/기술/서브미션) · 이름
private struct FavoriteStyleCardItem: View {
    let category: String
    let style: (any StyleSelectable)?
    let emptyText: String
    let onTapped: (() -> Void)?

    var body: some View {
        if let onTapped {
            Button(action: onTapped) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let style {
                style.iconImage.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            } else {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.primitive.coolGray.cg50)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(Font.pretendard.labelM)
                    .foregroundStyle(Color.component.skillCard.default.labelText)

                Text(style?.tabTitle ?? emptyText)
                    .font(.pretendard.custom(weight: .semiBold, size: 14))
                    .foregroundStyle(
                        style == nil
                            ? Color.component.skillCard.default.titleTextEmpty
                            : Color.component.skillCard.default.titleTextFilled
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - EmptyStyleView

/// 스타일 정보가 전혀 없을 때 표시되는 뷰
public struct EmptyStyleView: View {
    let onRegisterStyleTapped: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            Text("나의 주짓수를 보여주세요")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)
                .padding(.bottom, 8)

            Text("최애 포지션, 기술 등을 등록해보세요.")
                .font(Font.pretendard.bodyM)
                .foregroundStyle(Color.component.sectionHeader.subTitle)

            Button {
                onRegisterStyleTapped()
            } label: {
                AppButtonConfiguration(title: "내 스타일 등록하기", size: .medium)
            }
            .appButtonStyle(.tint, size: .medium, height: 38)
            .padding(.top, 24)

            DecorativeCardsView()
                .padding(.top, 16)
        }
    }
}

// MARK: - DecorativeCardsView

/// 장식용 스타일 카드 배치 뷰
private struct DecorativeCardsView: View {
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
        .frame(height: 282)
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
        favoritePosition: PositionType.guard,
        favoriteTechnique: TechniqueType.escapes,
        favoriteSubmission: SubmissionType.armLocks,
        onStyleCardTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileStyleSectionView - 일부 정보만") {
    MyProfileStyleSectionView(
        favoritePosition: nil,
        favoriteTechnique: TechniqueType.escapes,
        favoriteSubmission: nil,
        onStyleCardTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("EmptyStyleView") {
    EmptyStyleView(
        onRegisterStyleTapped: { }
    )
    .padding()
    .background(Color.component.background.default)
}
