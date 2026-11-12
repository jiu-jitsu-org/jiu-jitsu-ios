//
//  BeltSelectButton.swift
//  DesignSystem
//
//  Created by hansol on 10/30/26.
//

import SwiftUI

/// 띠를 고르는 버튼입니다.
///
/// '화이트', '블루' 글자만으로는 한눈에 구분이 어려워, 글자 위에 띠 모양(색 + 단)을 함께 그립니다.
/// 띠를 고르는 화면이 늘어나도 모양이 같도록 이 버튼을 공용으로 씁니다.
///
/// ## 크기
/// - `regular`: 띠 위·글자 아래. 한 줄에 다섯 띠를 나란히 둘 때 (기본)
/// - `compact`: 띠와 글자를 한 줄로. 세로 공간이 좁은 곳, 다른 입력 사이에 끼울 때
/// - `large`: 띠를 크게. 띠 고르기가 그 화면의 주 질문일 때
///
/// ## 사용 예시
/// ```swift
/// BeltSelectButton(color: .blue, title: "블루", isSelected: true) {
///     store.send(.beltSelected(.blue))
/// }
///
/// // 그랄까지 보여줄 때
/// BeltSelectButton(color: .purple, title: "퍼플", stripes: 2, size: .large, isSelected: false) { }
/// ```
public struct BeltSelectButton: View {

    // MARK: - Types

    /// 띠 색. 도메인의 띠 등급과 1:1로 맞춰 쓴다.
    public enum BeltColor: Sendable {
        case white
        case blue
        case purple
        case brown
        case black
    }

    public enum Size: Equatable, Sendable {
        case compact
        case regular
        case large
    }

    // MARK: - Properties

    private let color: BeltColor
    private let title: String
    private let stripes: Int
    private let size: Size
    private let isSelected: Bool
    private let action: () -> Void

    // MARK: - Initialization

    /// - Parameters:
    ///   - stripes: 단에 그릴 그랄 수(0~4). 0이면 그리지 않는다.
    public init(
        color: BeltColor,
        title: String,
        stripes: Int = 0,
        size: Size = .regular,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.color = color
        self.title = title
        self.stripes = min(max(stripes, 0), 4)
        self.size = size
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            content
                // 한글은 글자 아래 여백이 커서 기하 가운데면 위로 떠 보인다. 1pt 내려 눈으로 가운데에 맞춘다.
                .offset(y: size == .compact ? 0 : 1)
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
        }
        .buttonStyle(BeltSelectButtonStyle(isSelected: isSelected, cornerRadius: size.cornerRadius))
        .accessibilityLabel(stripes > 0 ? "\(title) \(stripes)그랄" : title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var content: some View {
        switch size {
        case .compact:
            HStack(spacing: 6) {
                BeltShape(color: color, stripes: stripes, size: size)
                label
            }
            .padding(.horizontal, 8)
        case .regular, .large:
            VStack(spacing: size == .large ? 10 : 6) {
                BeltShape(color: color, stripes: stripes, size: size)
                label
            }
        }
    }

    private var label: some View {
        Text(title)
            .font(.pretendard.custom(weight: .semiBold, size: size.fontSize))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(
                isSelected
                ? Color.component.beltSelectButton.selected.labelText
                : Color.component.beltSelectButton.unselected.labelText
            )
    }
}

// MARK: - Belt Icon

/// 띠 칩의 띠 그림만 따로 — 휠 같은 다른 부품의 아이콘 자리에서 칩과 같은 띠 모양을 쓴다.
public struct BeltIcon: View {
    private let color: BeltSelectButton.BeltColor
    private let size: BeltSelectButton.Size

    public init(color: BeltSelectButton.BeltColor, size: BeltSelectButton.Size = .regular) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        BeltShape(color: color, stripes: 0, size: size)
    }
}

// MARK: - Belt Illustration

/// 띠를 화면의 주인공으로 크게 그릴 때 — 칩의 `large` 띠 모양을 폭에 맞춰 그대로 키운다. 도형이라 커져도 흐려지지 않는다.
///
/// 그랄을 막 감은 모습을 보여 줄 때는 `newStripes`(새로 감은 그랄 수)와 `newStripeProgress`(0이면 비어 있고 1이면 다 감김)를 넘긴다.
/// 그랄은 띠 끝 쪽부터 감으므로 새 그랄은 단의 안쪽(왼쪽)에 생긴다.
public struct BeltIllustration: View {
    private let color: BeltSelectButton.BeltColor
    private let stripes: Int
    private let width: CGFloat
    private let newStripes: Int
    private let newStripeProgress: CGFloat

    public init(
        color: BeltSelectButton.BeltColor,
        stripes: Int,
        width: CGFloat,
        newStripes: Int = 0,
        newStripeProgress: CGFloat = 1
    ) {
        self.color = color
        self.stripes = min(max(stripes, 0), 4)
        self.width = width
        self.newStripes = min(max(newStripes, 0), self.stripes)
        self.newStripeProgress = newStripeProgress
    }

    public var body: some View {
        let large = BeltMetrics(BeltSelectButton.Size.large)
        BeltShape(
            color: color,
            stripes: stripes,
            metrics: large.scaled(by: width / large.beltSize.width),
            newStripes: newStripes,
            newStripeProgress: newStripeProgress
        )
    }
}

// MARK: - Button Style (Private)

/// 누르는 동안 바탕을 한 단계 진하게 — 다른 앱 버튼과 같은 눌림 반응.
private struct BeltSelectButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let colors = Color.component.beltSelectButton
        configuration.label
            .background(
                isSelected
                ? (configuration.isPressed ? colors.selected.pressedBg : colors.selected.bg)
                : (configuration.isPressed ? colors.unselected.pressedBg : colors.unselected.bg)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(Rectangle())
    }
}

// MARK: - Belt Shape (Private)

/// 가로로 놓인 띠 한 토막. 끝 쪽에 단(그랄을 감는 검은 자리)을 넣어 띠로 읽히게 한다.
private struct BeltShape: View {
    let color: BeltSelectButton.BeltColor
    let stripes: Int
    let metrics: BeltMetrics
    let newStripes: Int
    let newStripeProgress: CGFloat

    init(color: BeltSelectButton.BeltColor, stripes: Int, size: BeltSelectButton.Size) {
        self.init(color: color, stripes: stripes, metrics: BeltMetrics(size))
    }

    init(color: BeltSelectButton.BeltColor, stripes: Int, metrics: BeltMetrics, newStripes: Int = 0, newStripeProgress: CGFloat = 1) {
        self.color = color
        self.stripes = stripes
        self.metrics = metrics
        self.newStripes = newStripes
        self.newStripeProgress = newStripeProgress
    }

    var body: some View {
        RoundedRectangle(cornerRadius: metrics.beltCornerRadius)
            .fill(color.fill)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(color.rankBar)
                    .overlay {
                        HStack(spacing: metrics.stripeSpacing) {
                            ForEach(0..<stripes, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.component.beltSelectButton.belt.stripe)
                                    .frame(width: metrics.stripeWidth)
                                    // 새 그랄은 위에서 아래로 감긴다
                                    .scaleEffect(x: 1, y: index < newStripes ? newStripeProgress : 1, anchor: .top)
                            }
                        }
                    }
                    .frame(width: metrics.rankBarWidth)
                    .padding(.trailing, metrics.rankBarInset)
            }
            .clipShape(RoundedRectangle(cornerRadius: metrics.beltCornerRadius))
            .overlay {
                if color == .white {
                    RoundedRectangle(cornerRadius: metrics.beltCornerRadius)
                        .strokeBorder(Color.component.beltSelectButton.belt.whiteEdge, lineWidth: 1)
                }
            }
            .frame(width: metrics.beltSize.width, height: metrics.beltSize.height)
            .accessibilityHidden(true)
    }
}

// MARK: - Size Metrics

/// 띠 한 토막의 치수. 칩 크기마다 정해 두고, 크게 그릴 때는 같은 비율로 키운다.
private struct BeltMetrics {
    var beltSize: CGSize
    var beltCornerRadius: CGFloat
    var rankBarWidth: CGFloat
    var rankBarInset: CGFloat
    var stripeWidth: CGFloat
    var stripeSpacing: CGFloat

    init(_ size: BeltSelectButton.Size) {
        beltSize = size.beltSize
        beltCornerRadius = size.beltCornerRadius
        rankBarWidth = size.rankBarWidth
        rankBarInset = size.rankBarInset
        stripeWidth = size.stripeWidth
        stripeSpacing = size.stripeSpacing
    }

    func scaled(by factor: CGFloat) -> BeltMetrics {
        var metrics = self
        metrics.beltSize = CGSize(width: beltSize.width * factor, height: beltSize.height * factor)
        metrics.beltCornerRadius *= factor
        metrics.rankBarWidth *= factor
        metrics.rankBarInset *= factor
        metrics.stripeWidth *= factor
        metrics.stripeSpacing *= factor
        return metrics
    }
}

private extension BeltSelectButton.Size {
    var height: CGFloat {
        switch self {
        case .compact: return 40
        case .regular: return 56
        case .large: return 88
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact, .regular: return 10
        case .large: return 14
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .compact, .regular: return 14
        case .large: return 16
        }
    }

    var beltSize: CGSize {
        switch self {
        case .compact: return CGSize(width: 22, height: 7)
        case .regular: return CGSize(width: 32, height: 10)
        case .large: return CGSize(width: 52, height: 16)
        }
    }

    var beltCornerRadius: CGFloat {
        switch self {
        case .compact: return 1.5
        case .regular: return 2
        case .large: return 3
        }
    }

    /// 그랄 4줄이 들어가도록 줄 폭·간격과 함께 정한다.
    var rankBarWidth: CGFloat {
        switch self {
        case .compact: return 7
        case .regular: return 8
        case .large: return 15
        }
    }

    var rankBarInset: CGFloat {
        switch self {
        case .compact: return 3
        case .regular: return 4
        case .large: return 7
        }
    }

    var stripeWidth: CGFloat {
        switch self {
        case .compact: return 1
        case .regular: return 1
        case .large: return 1.5
        }
    }

    var stripeSpacing: CGFloat {
        switch self {
        case .compact: return 0.5
        case .regular: return 1
        case .large: return 1.5
        }
    }
}

private extension BeltSelectButton.BeltColor {
    var fill: Color {
        let belt = Color.component.beltSelectButton.belt
        switch self {
        case .white: return belt.white
        case .blue: return belt.blue
        case .purple: return belt.purple
        case .brown: return belt.brown
        case .black: return belt.black
        }
    }

    var rankBar: Color {
        let belt = Color.component.beltSelectButton.belt
        return self == .black ? belt.blackRankBar : belt.rankBar
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            BeltSelectButton(color: .white, title: "화이트", isSelected: false) {}
            BeltSelectButton(color: .blue, title: "블루", isSelected: true) {}
            BeltSelectButton(color: .purple, title: "퍼플", isSelected: false) {}
            BeltSelectButton(color: .brown, title: "브라운", isSelected: false) {}
            BeltSelectButton(color: .black, title: "블랙", isSelected: false) {}
        }
        HStack(spacing: 8) {
            BeltSelectButton(color: .blue, title: "블루", size: .compact, isSelected: true) {}
            BeltSelectButton(color: .purple, title: "퍼플", size: .compact, isSelected: false) {}
        }
        HStack(spacing: 8) {
            BeltSelectButton(color: .purple, title: "퍼플", stripes: 2, size: .large, isSelected: true) {}
            BeltSelectButton(color: .black, title: "블랙", stripes: 4, size: .large, isSelected: false) {}
        }
        BeltIllustration(color: .purple, stripes: 2, width: 300)
    }
    .padding(20)
}
