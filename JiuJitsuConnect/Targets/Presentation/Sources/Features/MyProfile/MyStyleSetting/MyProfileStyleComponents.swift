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

/// 최애 기술 섹션 (포지션 · 기술 · 서브미션 최애 한 장씩)
///
/// 제목은 '최애 기술'이다(#199). '최애 스타일'은 무엇을 말하는지 애매하다는 피드백이 있어,
/// 포지션·서브미션까지 넓게 '기술'로 묶어 부른다.
///
/// 처음에는 무엇을 골랐는지 안 보이게 뒤집힌 채 포개져 있고, 누르면 펼쳐지며 앞면이 나온다.
/// 특기는 자기 평가라 입력 부담이 커서 최애만 보여 준다(#118). 남이 보는 프로필도 같은 모양을 쓴다.
public struct MyProfileStyleSectionView: View {
    let favoritePosition: (any StyleSelectable)?
    let favoriteTechnique: (any StyleSelectable)?
    let favoriteSubmission: (any StyleSelectable)?
    /// 앞면 캐릭터가 맬 띠
    let beltRank: BeltRank?

    /// 펼친 카드를 눌러 수정한다. `nil`이면 읽기 전용(남이 보는 프로필)이라 다시 누르면 덮인다.
    let onStyleCardTapped: ((MyStyleSettingType) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = false
    @State private var width: CGFloat = 0

    public init(
        favoritePosition: (any StyleSelectable)?,
        favoriteTechnique: (any StyleSelectable)?,
        favoriteSubmission: (any StyleSelectable)?,
        beltRank: BeltRank?,
        onStyleCardTapped: ((MyStyleSettingType) -> Void)?
    ) {
        self.favoritePosition = favoritePosition
        self.favoriteTechnique = favoriteTechnique
        self.favoriteSubmission = favoriteSubmission
        self.beltRank = beltRank
        self.onStyleCardTapped = onStyleCardTapped
    }

    private struct Item {
        let type: MyStyleSettingType
        let style: (any StyleSelectable)?
    }

    private enum Metrics {
        static let spacing: CGFloat = 8
        /// 시안 카드 비율 (가로 ÷ 세로)
        static let cardRatio: CGFloat = 827.0 / 972.0
        /// 포갰을 때 — 카드 폭에 견준 가운데 자리, 아래로 내린 길이, 기울기
        static let pileCenterX: [CGFloat] = [0.58, 1.21, 1.84]
        static let pileOffsetY: [CGFloat] = [0, 0.085, 0]
        static let pileAngle: [Double] = [-21, 7.5, -21]
        /// 포갠 카드는 기울어 위아래로 더 나온다
        static let pileHeightRatio: CGFloat = 1.22
        static let flipAngle: Double = 180
    }

    private var items: [Item] {
        [
            Item(type: .position, style: favoritePosition),
            Item(type: .technique, style: favoriteTechnique),
            Item(type: .submission, style: favoriteSubmission)
        ]
    }

    /// 하나도 안 골랐으면 숨길 것이 없어 펼친 채로 둔다.
    private var showsOpen: Bool {
        isOpen || items.allSatisfy { $0.style == nil }
    }

    private var cardWidth: CGFloat {
        max(0, (width - Metrics.spacing * 2) / 3)
    }

    private var cardHeight: CGFloat {
        cardWidth / Metrics.cardRatio
    }

    private var stageHeight: CGFloat {
        showsOpen ? cardHeight : cardHeight * Metrics.pileHeightRatio
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("최애 기술")
                .font(.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)

            ZStack(alignment: .topLeading) {
                ForEach(Array(items.enumerated()), id: \.element.type) { index, item in
                    card(item, at: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: stageHeight, alignment: .topLeading)
            .animation(spreadAnimation(at: 0), value: showsOpen)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
    }

    private func card(_ item: Item, at index: Int) -> some View {
        Button {
            cardTapped(item.type)
        } label: {
            FlipCard(angle: showsOpen ? 0 : Metrics.flipAngle) {
                FavoriteStyleCardFront(
                    category: item.type.title,
                    style: item.style,
                    beltRank: beltRank,
                    // 좁은 기기(375pt)에서는 한 줄에 다 들어가지 않아 '지정해주세/요'로 끊긴다.
                    // 보이지 않는 줄바꿈 자리(U+200B)를 두어 넘어갈 때는 '지정해/주세요'로 넘어가게 한다.
                    emptyText: onStyleCardTapped == nil ? "아직 안 골랐어요" : "지정해\u{200B}주세요"
                )
                .frame(width: cardWidth, height: cardHeight)
            } back: {
                FavoriteStyleCardBack(category: item.type.title)
                    .frame(width: cardWidth, height: cardHeight)
            }
            .animation(flipAnimation(at: index), value: showsOpen)
            .contentShape(RoundedRectangle(cornerRadius: FavoriteStyleCardMetrics.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: item))
        .rotationEffect(.degrees(showsOpen ? 0 : Metrics.pileAngle[index]))
        .position(center(at: index))
        .animation(spreadAnimation(at: index), value: showsOpen)
    }

    private func center(at index: Int) -> CGPoint {
        if showsOpen {
            return CGPoint(
                x: cardWidth / 2 + CGFloat(index) * (cardWidth + Metrics.spacing),
                y: cardHeight / 2
            )
        }
        return CGPoint(
            x: cardWidth * Metrics.pileCenterX[index],
            y: cardHeight * (Metrics.pileHeightRatio / 2 + Metrics.pileOffsetY[index] - 0.04)
        )
    }

    private func cardTapped(_ type: MyStyleSettingType) {
        guard showsOpen else {
            isOpen = true
            return
        }
        if let onStyleCardTapped {
            // 다 빈 채로 펼쳐져 있다가 하나를 고르고 돌아와도 다시 덮이지 않게 한다.
            isOpen = true
            onStyleCardTapped(type)
        } else {
            isOpen = false
        }
    }

    private func accessibilityLabel(for item: Item) -> String {
        guard showsOpen else { return "최애 \(item.type.title) 카드, 펼쳐 보기" }
        return "최애 \(item.type.title), \(item.style?.tabTitle ?? "없음")"
    }

    // MARK: - Animation

    /// 맨 위(오른쪽) 카드부터 미끄러지듯 자리를 잡는다.
    private func spreadAnimation(at index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return .spring(response: 0.5, dampingFraction: 0.78).delay(Double(2 - index) * 0.05)
    }

    /// 펼쳐지는 동안 왼쪽부터 차례로 뒤집힌다.
    private func flipAnimation(at index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return .spring(response: 0.55, dampingFraction: 0.75).delay(0.1 + Double(index) * 0.1)
    }
}

// MARK: - FavoriteStyleCard

private enum FavoriteStyleCardMetrics {
    static let cornerRadius: CGFloat = 16
}

/// 뒷면 — 로고와 분류만. 무엇을 골랐는지는 적지 않는다.
private struct FavoriteStyleCardBack: View {
    let category: String

    var body: some View {
        StyleCardBackSurface(cornerRadius: FavoriteStyleCardMetrics.cornerRadius)
            .overlay {
                VStack(spacing: 10) {
                    Assets.Splash.logo.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54)

                    Text(category)
                        .font(.pretendard.custom(weight: .medium, size: 13))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
    }
}

/// 앞면 — 설정 화면 큰 카드와 같은 바탕 무늬에 내 띠 캐릭터 · 분류 · 이름
private struct FavoriteStyleCardFront: View {
    let category: String
    let style: (any StyleSelectable)?
    let beltRank: BeltRank?
    let emptyText: String

    var body: some View {
        Group {
            if let style {
                filled(style)
            } else {
                empty
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: FavoriteStyleCardMetrics.cornerRadius))
    }

    private func filled(_ style: any StyleSelectable) -> some View {
        VStack(spacing: 0) {
            style.poseImage(belt: beltRank ?? .white).swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(category)
                .font(.pretendard.custom(weight: .medium, size: 11))
                .foregroundStyle(Color.white.opacity(0.8))

            Text(style.fullTitle)
                .font(.cookieRun.custom(weight: .black, size: 15))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            style.backgroundImage.swiftUIImage
                .resizable()
                .scaledToFill()
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primitive.coolGray.cg50)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.skillCard.default.labelText)

                Text(emptyText)
                    .font(.pretendard.custom(weight: .semiBold, size: 16))
                    .foregroundStyle(Color.component.skillCard.default.titleTextEmpty)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.component.skillCard.default.bg)
    }
}

// MARK: - EmptyStyleView

/// 스타일 정보가 전혀 없을 때 표시되는 뷰
public struct EmptyStyleView: View {
    // 비로그인 MY(#242)는 등록할 수 없어 버튼 없이 안내와 카드만 보인다.
    var showsRegisterButton: Bool = true
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

            if showsRegisterButton {
                Button {
                    onRegisterStyleTapped()
                } label: {
                    AppButtonConfiguration(title: "내 스타일 등록하기", size: .medium)
                }
                .appButtonStyle(.tint, size: .medium, height: 38)
                .padding(.top, 24)
            }

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
        beltRank: .blue,
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
        beltRank: nil,
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
