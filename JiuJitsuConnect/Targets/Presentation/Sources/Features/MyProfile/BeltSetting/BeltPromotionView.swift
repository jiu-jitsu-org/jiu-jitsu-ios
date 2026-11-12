import SwiftUI
import Domain
import DesignSystem

/// MY에서 띠나 그랄을 올려 저장했을 때 축하할 일(#278, #286).
public enum BeltPromotion: Equatable, Identifiable, Sendable {
    /// 더 높은 띠로 바꿈
    case belt(BeltRank)
    /// 같은 띠에서 그랄만 늘림
    case stripe(BeltRank, from: BeltStripe, to: BeltStripe)

    public var id: String {
        switch self {
        case let .belt(rank): return rank.id
        case let .stripe(rank, from, to): return "\(rank.id)-\(from.id)-\(to.id)"
        }
    }

    /// 저장 전후 프로필을 비교해 축하할 일을 고른다. 처음 등록했거나, 띠를 내렸거나, 같은 띠에서 그랄을 내리거나 그대로 두면 nil.
    init?(from old: CommunityProfile?, to new: CommunityProfile) {
        guard let oldRank = old?.beltRank,
              let newRank = new.beltRank,
              let oldIndex = BeltRank.allCases.firstIndex(of: oldRank),
              let newIndex = BeltRank.allCases.firstIndex(of: newRank)
        else { return nil }

        if newIndex > oldIndex {
            self = .belt(newRank)
            return
        }
        let oldStripe = old?.beltStripe ?? BeltStripe.none
        guard newIndex == oldIndex,
              let newStripe = new.beltStripe,
              newStripe.count > oldStripe.count
        else { return nil }
        self = .stripe(newRank, from: oldStripe, to: newStripe)
    }
}

/// 띠·그랄을 올려 저장했을 때 잠깐 덮는 축하 장면(#278, #286).
///
/// 띠 승급은 새 띠 캐릭터가 화면 아래에서 올라오고, 그랄은 띠를 크게 그려 새로 감은 그랄이 채워진다.
/// 둘 다 대회 완료 화면과 같은 종이 꽃가루가 퍼진다. 아무 데나 누르거나 2초가 지나면 옅어지며 사라진다.
struct BeltPromotionView: View {
    let promotion: BeltPromotion
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    @State private var isStripeAdded = false
    @State private var isClosing = false

    private enum Metrics {
        // 캐릭터는 화면 높이의 절반, 최대 400pt. 참가 그림을 세로 1200px(=400pt@3x)로 다시 뽑아 늘리지 않고 그린다(#285).
        static let characterHeightRatio: CGFloat = 0.5
        static let maxCharacterHeight: CGFloat = 400
        static let titleGap: CGFloat = 32
        // 그랄 축하의 띠는 양옆을 비우고 이 폭까지만 커진다.
        static let beltSideInset: CGFloat = 40
        static let maxBeltWidth: CGFloat = 300
        static let beltTitleGap: CGFloat = 40
    }

    private enum Motion {
        // 끝을 넘지 않고 제자리에 닿는 곡선 — 대회 완료 화면 캐릭터가 올라오는 움직임과 같다.
        static let appear = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)
        static let disappear = Animation.easeOut(duration: 0.25)
        // 장면이 다 보인 뒤 그랄이 위에서 아래로 감긴다.
        static let stripe = Animation.easeInOut(duration: 0.5).delay(0.35)
        static let stay: Duration = .seconds(2)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.primitive.coolGray.cg25

                switch promotion {
                case let .belt(belt):
                    PaperConfettiView(startDelay: 0.2)
                    beltScene(belt: belt, size: proxy.size)
                case let .stripe(belt, from, to):
                    // 그랄이 다 감길 즈음 퍼진다.
                    PaperConfettiView(startDelay: 0.7)
                    stripeScene(belt: belt, from: from, to: to, width: proxy.size.width)
                }
            }
            .opacity(isShown ? 1 : 0)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { Task { await close() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("누르면 닫혀요")
        .sensoryFeedback(.success, trigger: isShown) { _, isNowShown in isNowShown }
        .presentationBackground(.clear)
        .task {
            if reduceMotion {
                isShown = true
                isStripeAdded = true
            } else {
                withAnimation(Motion.appear) { isShown = true }
                withAnimation(Motion.stripe) { isStripeAdded = true }
            }
            guard (try? await Task.sleep(for: Motion.stay)) != nil else { return }
            await close()
        }
    }

    // MARK: - View Components

    private func title(_ text: String) -> some View {
        Text(text)
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }

    /// 메달을 걸지 않은 '참가' 그림이 띠 캐릭터 한 장이라 그대로 쓴다. 밑단은 잘린 단면이라 화면 아래 끝에 붙인다.
    private func beltScene(belt: BeltRank, size: CGSize) -> some View {
        let character = MedalCharacter(belt: belt, rank: .participation)
        let height = min(size.height * Metrics.characterHeightRatio, Metrics.maxCharacterHeight)

        return VStack(spacing: Metrics.titleGap) {
            title("\(belt.displayName)띠 승급을 축하해요!")

            character.image
                .resizable()
                .frame(width: height * character.aspectRatio, height: height)
                // 키우지 않고 아래에서 올라온다 — 원본보다 크게 그려지는 순간이 없다.
                .offset(y: isShown ? 0 : height)
                .accessibilityHidden(true)
        }
    }

    private func stripeScene(belt: BeltRank, from: BeltStripe, to: BeltStripe, width: CGFloat) -> some View {
        VStack(spacing: Metrics.beltTitleGap) {
            title("\(belt.displayName)띠 \(to.displayName)을 축하해요!")

            BeltIllustration(
                color: belt.selectButtonColor,
                stripes: to.count,
                width: min(width - Metrics.beltSideInset * 2, Metrics.maxBeltWidth),
                newStripes: to.count - from.count,
                newStripeProgress: isStripeAdded ? 1 : 0
            )
        }
        .frame(maxHeight: .infinity)
    }

    /// 눌렀거나 시간이 다 되었을 때 부른다. 어느 쪽이 먼저든 한 번만 닫는다.
    private func close() async {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(reduceMotion ? nil : Motion.disappear) { isShown = false }
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(250))
        }
        onDismiss()
    }
}

// MARK: - Preview

#Preview("띠") {
    BeltPromotionView(promotion: .belt(.blue), onDismiss: {})
}

#Preview("그랄") {
    BeltPromotionView(promotion: .stripe(.blue, from: .one, to: .two), onDismiss: {})
}
