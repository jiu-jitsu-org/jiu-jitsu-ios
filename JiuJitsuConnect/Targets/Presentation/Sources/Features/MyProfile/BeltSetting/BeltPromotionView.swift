import SwiftUI
import Domain
import DesignSystem

/// MY에서 띠나 그랄을 올려 저장했을 때 축하할 일(#278, #286).
public enum BeltPromotion: Equatable, Identifiable, Sendable {
    /// 더 높은 띠로 바꿈. 장면이 옛 띠·그랄에서 새 띠로 바뀌는 순간을 그려서 옛 값을 함께 둔다.
    case belt(BeltRank, from: BeltRank, fromStripe: BeltStripe)
    /// 같은 띠에서 그랄만 늘림
    case stripe(BeltRank, from: BeltStripe, to: BeltStripe)

    public var id: String {
        switch self {
        case let .belt(rank, from, _): return "\(from.id)-\(rank.id)"
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

        let oldStripe = old?.beltStripe ?? BeltStripe.none
        if newIndex > oldIndex {
            self = .belt(newRank, from: oldRank, fromStripe: oldStripe)
            return
        }
        guard newIndex == oldIndex,
              let newStripe = new.beltStripe,
              newStripe.count > oldStripe.count
        else { return nil }
        self = .stripe(newRank, from: oldStripe, to: newStripe)
    }
}

/// 띠·그랄을 올려 저장했을 때 잠깐 덮는 축하 장면(#278, #286).
///
/// 둘 다 MY 헤더의 사진 링을 크게 키워 가운데에 두고, 링이 바뀌는 순간을 보여 준다.
/// - 그랄: 링이 헤더 등장처럼 두 바퀴 돈 뒤, 새 그랄이 링 바깥에서 안쪽으로 그려진다.
/// - 띠: 옛 띠 색 링이 도는 동안 옛 그랄이 지워지고, 새 띠 색이 12시부터 시계 방향으로 덮인다.
/// 다 바뀌면 링이 한 번 통 튀고 띠 색 테가 퍼지며, 새 띠 색 꽃가루가 한 번 터진다.
/// 오른쪽 위 닫기(X)를 눌러야만 옅어지며 사라진다(#339).
struct BeltPromotionView: View {
    let promotion: BeltPromotion
    /// MY 헤더와 같은 사진. 없으면 헤더의 빈 사진 모양.
    var profileImageUrl: String?
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    @State private var isClosing = false
    /// 등장 페이드가 끝나 장면이 다 보인 뒤에만 닫기가 눌리고 VoiceOver에 잡힌다.
    @State private var isCloseEnabled = false

    // 링이 바뀌는 순간 — 모두 0에서 출발해 끝값으로 간다.
    /// 등장 움직임 경과(ms). MyBeltRingView와 같은 곡선.
    @State private var spinTime: Double = 0
    /// 새 그랄이 링 바깥에서 안쪽으로 그려진 정도
    @State private var newStripeProgress: CGFloat = 0
    /// 새 띠 색이 링을 덮은 정도
    @State private var beltDrawProgress: CGFloat = 0
    /// 옛 띠의 그랄 — 띠가 바뀌면 지운다
    @State private var oldStripeOpacity: Double = 1
    /// 다 바뀐 순간의 통 튐
    @State private var pulseScale: CGFloat = 1
    /// 다 바뀐 순간 퍼지는 띠 색 테(0 → 1)
    @State private var burstProgress: CGFloat = 0
    @State private var isConfettiShown = false
    /// 링 가운데(장면 좌표). 꽃가루가 여기서 터지고 바탕 빛도 여기를 비춘다.
    @State private var ringCenter: CGPoint?

    private enum Metrics {
        static let titleGap: CGFloat = 36
        /// MY 헤더 링(사진 90) 대비 배율 — 사진 135, 링 약 10.5, 전체 168
        static let ringScale: CGFloat = 1.5
        /// 퍼지는 테가 닿는 크기(링 대비)
        static let burstScale: CGFloat = 1.28
        // 닫기는 다른 화면 머리줄(높이 60·양옆 16)의 오른쪽 아이콘 자리 — 아이콘 24 오른쪽 끝이 화면에서 16, 누르는 칸은 44.
        static let headerHeight: CGFloat = 60
        static let headerSideInset: CGFloat = 16
        static let closeIcon: CGFloat = 24
        static let closeGlyph: CGFloat = 18
        static let closeTapSize: CGFloat = 44
        /// 빈 사진 아이콘 — 헤더와 같은 64pt 고정. 원본이 24pt PNG라 사진 크기에 맞춰 키우면 깨진다.
        static let emptyPhotoIcon: CGFloat = 64
    }

    private enum Motion {
        // 끝을 넘지 않고 제자리에 닿는 곡선 — 대회 완료 화면 캐릭터가 올라오는 움직임과 같다.
        static let appear = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)
        static let disappear = Animation.easeOut(duration: 0.25)
        static let reduced = Animation.easeOut(duration: 0.25)
        // 그랄: 두 바퀴 돈 뒤 새 그랄이 그려지고, 다 그려지면 축하
        static let stripeDraw = Animation.easeInOut(duration: 0.45).delay(1.15)
        static let stripeCelebrateAt: Duration = .milliseconds(1550)
        // 띠: 도는 동안 옛 그랄이 지워지고 새 띠 색이 덮인 뒤 축하
        static let oldStripeFade = Animation.easeInOut(duration: 0.3).delay(0.3)
        static let beltDraw = Animation.easeInOut(duration: 1.0).delay(0.25)
        static let beltCelebrateAt: Duration = .milliseconds(1300)
        // 축하: 링이 1.05배로 통 튀었다 돌아오고, 띠 색 테가 0.8초 동안 퍼지며 사라진다.
        static let pulseUp = Animation.spring(duration: 0.18, bounce: 0)
        static let pulseDown = Animation.spring(duration: 0.4, bounce: 0.45)
        static let burst = Animation.easeOut(duration: 0.8)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { proxy in
                ZStack {
                    background(size: proxy.size)

                    VStack(spacing: Metrics.titleGap) {
                        title
                        ring
                            .onGeometryChange(for: CGPoint.self) { geometry in
                                let frame = geometry.frame(in: .named(Self.stageSpace))
                                return CGPoint(x: frame.midX, y: frame.midY)
                            } action: { ringCenter = $0 }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if isConfettiShown {
                        PaperConfettiView(
                            startDelay: 0,
                            colors: confettiColors,
                            burstOrigin: ringCenter,
                            isOneShot: true
                        )
                    }
                }
                .coordinateSpace(name: Self.stageSpace)
            }
            .ignoresSafeArea()

            // 장면은 화면 끝까지 덮고, 닫기만 안전 영역 아래 머리줄 자리에 둔다.
            closeButton
                .padding(.top, (Metrics.headerHeight - Metrics.closeTapSize) / 2)
                .padding(.trailing, Metrics.headerSideInset - (Metrics.closeTapSize - Metrics.closeIcon) / 2)
        }
        .opacity(isShown ? 1 : 0)
        .sensoryFeedback(.success, trigger: isShown) { _, isNowShown in isNowShown }
        .presentationBackground(.clear)
        .task { await play() }
    }

    private static let stageSpace = "beltPromotionStage"

    // MARK: - View Components

    /// 회색 바탕 가운데(링 자리)에 흰 빛을 비춘다 — 반지름의 70%쯤에서 바탕색으로 잦아든다.
    private func background(size: CGSize) -> some View {
        let center = ringCenter.map { UnitPoint(x: $0.x / max(size.width, 1), y: $0.y / max(size.height, 1)) } ?? .center
        return RadialGradient(
            stops: [
                .init(color: Color.primitive.bw.trueWhite, location: 0),
                .init(color: Color.primitive.coolGray.cg25, location: 0.7),
            ],
            center: center,
            startRadius: 0,
            endRadius: size.width
        )
        .background(Color.primitive.coolGray.cg25)
    }

    /// 면 없이 아이콘만 — 약관 화면 닫기와 같은 xmark(18 semibold, 24 칸).
    private var closeButton: some View {
        Button {
            Task { await close() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: Metrics.closeGlyph, weight: .semibold))
                .foregroundStyle(Color.component.header.iconButton)
                .frame(width: Metrics.closeIcon, height: Metrics.closeIcon)
                .frame(width: Metrics.closeTapSize, height: Metrics.closeTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isCloseEnabled)
        .accessibilityLabel("닫기")
        .accessibilityHidden(!isCloseEnabled)
    }

    private var title: some View {
        Text(titleText)
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }

    private var titleText: String {
        switch promotion {
        case let .belt(belt, _, _): return "\(belt.displayName)띠 승급을 축하해요!"
        case let .stripe(belt, _, to): return "\(belt.displayName)띠 \(to.displayName)을 축하해요!"
        }
    }

    /// MY 헤더의 사진 링을 크게. 링만 돌고 사진은 돌지 않으며, 웅크리고 튀는 건 사진과 링이 함께다.
    private var ring: some View {
        let geometry = MyBeltRingGeometry(scale: Metrics.ringScale)
        return ZStack {
            // 다 바뀐 순간 링 밖으로 퍼지며 사라지는 띠 색 테
            Circle()
                .inset(by: geometry.box / 2 - geometry.radius)
                .stroke(newBelt.beltSurfaceColor, lineWidth: geometry.width)
                .frame(width: geometry.box, height: geometry.box)
                .modifier(BurstRing(progress: burstProgress, maxScale: Metrics.burstScale))

            photo(diameter: geometry.photo)
                .frame(width: geometry.photo, height: geometry.photo)
                .clipShape(Circle())

            ringStroke(geometry: geometry)
                .myBeltRingEntranceRotation(time: spinTime)
        }
        .frame(width: geometry.box, height: geometry.box)
        .scaleEffect(pulseScale)
        .myBeltRingEntranceScale(time: spinTime)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func ringStroke(geometry: MyBeltRingGeometry) -> some View {
        switch promotion {
        case let .belt(belt, from, fromStripe):
            MyBeltRingStroke(
                geometry: geometry,
                beltRank: from,
                stripeCount: fromStripe.count,
                drawingBelt: belt,
                drawProgress: beltDrawProgress,
                stripeOpacity: oldStripeOpacity
            )
        case let .stripe(belt, from, to):
            MyBeltRingStroke(
                geometry: geometry,
                beltRank: belt,
                stripeCount: to.count,
                newStripes: to.count - from.count,
                newStripeProgress: newStripeProgress
            )
        }
    }

    /// 헤더와 같은 사진 — 불러오는 중·실패·없음이면 흰 원 위 기본 사람 아이콘.
    @ViewBuilder
    private func photo(diameter: CGFloat) -> some View {
        ZStack {
            Color.component.list.setting.background

            if let profileImageUrl,
               let url = URL(string: profileImageUrl),
               url.scheme == "https" || url.scheme == "http" {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        emptyPhotoIcon(diameter: diameter)
                    }
                }
            } else {
                emptyPhotoIcon(diameter: diameter)
            }
        }
    }

    private func emptyPhotoIcon(diameter: CGFloat) -> some View {
        Assets.Common.Icon.profile.swiftUIImage
            .resizable()
            .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
            .frame(width: Metrics.emptyPhotoIcon, height: Metrics.emptyPhotoIcon)
    }

    private var newBelt: BeltRank {
        switch promotion {
        case let .belt(belt, _, _): return belt
        case let .stripe(belt, _, _): return belt
        }
    }

    /// 새 띠 색 · 흰색 · 옅은 띠 색 한 번만.
    private var confettiColors: [Color] {
        let belt = newBelt.beltSurfaceColor
        return [belt, Color.primitive.bw.trueWhite, belt.opacity(0.45)]
    }

    // MARK: - Motion

    private func play() async {
        guard !reduceMotion else {
            // 동작 줄이기: 돌고 그리는 움직임 없이 다 바뀐 모습을 옅게 띄운다.
            spinTime = MyBeltRingEntrance.total
            newStripeProgress = 1
            beltDrawProgress = 1
            oldStripeOpacity = 0
            withAnimation(Motion.reduced) { isShown = true } completion: { isCloseEnabled = true }
            return
        }
        withAnimation(Motion.appear) { isShown = true } completion: { isCloseEnabled = true }
        // 0에서 출발한 프레임이 한 번 그려진 뒤에 돌기 시작한다.
        try? await Task.sleep(for: .milliseconds(16))
        guard !Task.isCancelled else { return }
        withAnimation(.linear(duration: MyBeltRingEntrance.total / 1000)) { spinTime = MyBeltRingEntrance.total }

        let celebrateAt: Duration
        switch promotion {
        case .stripe:
            withAnimation(Motion.stripeDraw) { newStripeProgress = 1 }
            celebrateAt = Motion.stripeCelebrateAt
        case .belt:
            withAnimation(Motion.oldStripeFade) { oldStripeOpacity = 0 }
            withAnimation(Motion.beltDraw) { beltDrawProgress = 1 }
            celebrateAt = Motion.beltCelebrateAt
        }

        try? await Task.sleep(for: celebrateAt - .milliseconds(16))
        guard !Task.isCancelled else { return }
        isConfettiShown = true
        withAnimation(Motion.burst) { burstProgress = 1 }
        withAnimation(Motion.pulseUp) { pulseScale = 1.05 } completion: {
            withAnimation(Motion.pulseDown) { pulseScale = 1 }
        }
    }

    /// 닫기를 눌렀을 때 부른다. 연달아 눌러도 한 번만 닫는다.
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

/// 다 바뀐 순간 링 밖으로 퍼지는 테. 0이면 보이지 않고, 0 → 1로 가며 maxScale까지 커지며 옅어진다.
private struct BurstRing: ViewModifier, Animatable {
    var progress: CGFloat
    let maxScale: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (maxScale - 1) * progress)
            .opacity(progress > 0 ? Double(1 - progress) * 0.8 : 0)
    }
}

// MARK: - Preview

#Preview("띠") {
    BeltPromotionView(promotion: .belt(.purple, from: .blue, fromStripe: .two), onDismiss: {})
}

#Preview("그랄") {
    BeltPromotionView(promotion: .stripe(.purple, from: .none, to: .one), onDismiss: {})
}
