//
//  MyBeltRingView.swift
//  Presentation
//
//  MY 헤더 사진 둘레의 띠 링과 등장 움직임 (#320).
//  모양은 웹 BeltAvatar(belt-avatar.tsx)를 MY 크기로 키운 것이다.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - MyBeltRingView

/// 사진(content) 둘레에 띠 링을 그린다. 링만 돌고 사진은 돌지 않으며, 커지고 작아지는 건 사진과 링이 함께다.
///
/// 사진 → 틈(4) → 띠 색 링(7). 링 아래에는 사진 쪽으로 번지는 흰 테(halo)가 깔리고,
/// 오른쪽 아래(135°)가 띠 끝 검은 칸, 그 위에 흰 그랄 줄이 놓인다. 띠가 없으면 점선 링만.
struct MyBeltRingView<Content: View>: View {
    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    /// 오를 때마다 등장 움직임을 한 번 한다. 언제 올릴지는 MyProfileFeature가 정한다(세션 첫 MY · 띠 바꾼 직후).
    var entranceTrigger: Int = 0
    /// 오를 때마다 다시 보기 움직임을 한 번 한다(#338) — 사진을 눌렀을 때. 움직이는 중이면 처음부터 다시 하지 않고 무시한다.
    var replayTrigger: Int = 0
    /// MY 헤더 크기(1) 대비 배율. 승급 축하 장면은 같은 링을 크게 그린다.
    var scale: CGFloat = 1
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinToken = 0
    /// 마지막으로 시작한 움직임. 다른 화면에서 돌아와 뷰가 다시 나타나면 task가 같은 토큰으로 다시 도는데, 이미 한 움직임은 다시 하지 않는다.
    @State private var playedSpinToken = 0
    @State private var spinKind = SpinKind.entrance
    /// 움직임을 시작한 때. 끝나기 전 다시 누르면 무시하는 데 쓴다.
    @State private var spinStartedAt: Date?
    /// 움직임 경과 시간(ms). 0 → total로 선형 애니메이션하고, 곡선은 매 프레임 Motion.frame이 계산한다.
    @State private var spinTime = Motion.total

    var body: some View {
        let ring = MyBeltRingGeometry(scale: scale)
        ZStack {
            content
                .frame(width: ring.photo, height: ring.photo)
                .clipShape(Circle())

            MyBeltRingStroke(geometry: ring, beltRank: beltRank, stripeCount: beltStripe?.count ?? 0)
                .modifier(SpinRotation(time: spinTime, kind: spinKind))
                .allowsHitTesting(false)
        }
        .frame(width: ring.box, height: ring.box)
        .modifier(SpinScale(time: spinTime, kind: spinKind))
        .onChange(of: entranceTrigger) { _, _ in
            guard !reduceMotion else { return }
            spinKind = .entrance
            spinToken += 1
        }
        .onChange(of: replayTrigger) { _, _ in
            guard !reduceMotion else { return }
            if let spinStartedAt, Date.now.timeIntervalSince(spinStartedAt) < Motion.total / 1000 { return }
            spinKind = .replay
            spinToken += 1
        }
        .task(id: spinToken) {
            guard spinToken > playedSpinToken else { return }
            playedSpinToken = spinToken
            spinStartedAt = .now
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { spinTime = 0 }
            // 0으로 돌린 프레임이 한 번 그려진 뒤에 출발해야 처음부터 돈다.
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: Motion.total / 1000)) { spinTime = Motion.total } completion: {
                spinKind = .entrance
            }
        }
    }
}

// MARK: - Ring Stroke

/// 사진 둘레의 링만 — 흰 테(halo) · 띠 색 링 · 띠 끝 검은 칸 · 흰 그랄 줄. 띠가 없으면 점선 링만.
///
/// MY 헤더는 그대로 그리고, 승급 축하 장면(BeltPromotionView)은 아래 값으로 바뀌는 순간을 그린다.
/// - `drawingBelt`/`drawProgress`: 새 띠 색이 12시부터 시계 방향으로 덮인다(0이면 없음, 1이면 한 바퀴).
/// - `newStripes`/`newStripeProgress`: 뒤쪽 그랄 N줄이 링 바깥에서 안쪽으로 그려진다.
/// - `stripeOpacity`: 그랄 줄 전체를 흐리게(띠가 바뀔 때 옛 그랄을 지운다).
struct MyBeltRingStroke: View {
    let geometry: MyBeltRingGeometry
    let beltRank: BeltRank?
    let stripeCount: Int
    var drawingBelt: BeltRank?
    var drawProgress: CGFloat = 0
    var newStripes: Int = 0
    var newStripeProgress: CGFloat = 1
    var stripeOpacity: Double = 1

    var body: some View {
        let ring = geometry
        if let beltRank {
            let topBelt = drawingBelt ?? beltRank
            ZStack {
                halo(beltRank)
                    .opacity(drawingBelt == nil ? 1 : 1 - drawProgress)
                if let drawingBelt {
                    halo(drawingBelt)
                        .opacity(drawProgress)
                }
                Circle()
                    .inset(by: ring.box / 2 - ring.radius)
                    .stroke(beltRank.beltSurfaceColor, lineWidth: ring.width)
                if let drawingBelt {
                    Circle()
                        .inset(by: ring.box / 2 - ring.radius)
                        .trim(from: 0, to: drawProgress)
                        .stroke(drawingBelt.beltSurfaceColor, lineWidth: ring.width)
                        // trim은 3시에서 출발한다 — 12시부터 덮이게 돌려 둔다.
                        .rotationEffect(.degrees(-90))
                }
                RingArc(from: ring.barCenter - ring.barWidth / 2, to: ring.barCenter + ring.barWidth / 2, radius: ring.radius)
                    .stroke(
                        topBelt == .black ? Color.component.myBelt.blackRankBar : Color.component.myBelt.ringRankBar,
                        lineWidth: ring.width
                    )
                ForEach(0..<stripeCount, id: \.self) { index in
                    let count = Double(stripeCount)
                    let center = ring.barCenter + (Double(index) - (count - 1) / 2) * ring.markPitchDegrees
                    // 그랄은 띠 끝 쪽부터 감으므로 새 그랄은 단의 안쪽(뒤쪽 순서)에 생긴다 — BeltIllustration과 같은 규칙.
                    let isNew = index >= stripeCount - newStripes
                    RingStripe(
                        from: center - ring.markDegrees / 2,
                        to: center + ring.markDegrees / 2,
                        radius: ring.radius,
                        width: ring.width,
                        progress: isNew ? newStripeProgress : 1
                    )
                    .fill(Color.component.myBelt.stripe)
                }
                .opacity(stripeOpacity)
            }
            .frame(width: ring.box, height: ring.box)
        } else {
            Circle()
                .inset(by: ring.box / 2 - ring.radius)
                .stroke(
                    Color.component.myBelt.noBeltRing,
                    style: StrokeStyle(lineWidth: ring.width, dash: [ring.noBeltDash / 2, ring.noBeltDash / 2])
                )
                .frame(width: ring.box, height: ring.box)
        }
    }

    private func halo(_ beltRank: BeltRank) -> some View {
        Circle()
            .inset(by: geometry.box / 2 - (geometry.radius - 0.5 * geometry.scale))
            .stroke(haloColor(beltRank), lineWidth: geometry.width + geometry.gap + 3 * geometry.scale)
    }

    private func haloColor(_ beltRank: BeltRank) -> Color {
        beltRank.isLightBelt
            ? Color.component.myBelt.lightInk.opacity(MyBeltRingGeometry.haloOpacity * 0.24)
            : Color.primitive.bw.trueWhite.opacity(MyBeltRingGeometry.haloOpacity)
    }
}

// MARK: - Ring Metrics

enum MyBeltRing {
    /// 사진 + 틈 + 링 바깥 지름. 헤더 레이아웃은 이 크기를 차지한다(흰 테는 3pt씩 바깥으로 번진다).
    static let box: CGFloat = MyBeltRingGeometry(scale: 1).box
}

/// 링 치수. MY 헤더(배율 1)를 기준으로 정하고, 크게 그릴 때는 같은 비율로 키운다.
struct MyBeltRingGeometry {
    static let haloOpacity: Double = 0.7

    let scale: CGFloat
    var photo: CGFloat { 90 * scale }
    var gap: CGFloat { 4 * scale }
    var width: CGFloat { 7 * scale }
    var mark: CGFloat { 3.5 * scale }
    var box: CGFloat { photo + 2 * (gap + width) }
    /// 링 중심선 반지름
    var radius: CGFloat { photo / 2 + gap + width / 2 }
    var barCenter: Double { 135 }
    var barWidth: Double { 44 }
    var markDegrees: Double { Double(mark / (2 * .pi * radius)) * 360 }
    var markPitchDegrees: Double { Double(mark * 2.4 / (2 * .pi * radius)) * 360 }
    /// 띠 없음 점선 한 칸(선+틈) — 둘레에 딱 나눠떨어지게
    var noBeltDash: CGFloat {
        let circumference = 2 * .pi * radius
        return circumference / (circumference / 12).rounded()
    }
}

/// 12시 = 0°, 시계 방향 각도로 그린 원호. 굵기는 stroke로 준다.
private struct RingArc: Shape {
    let from: Double
    let to: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: .degrees(from - 90),
            endAngle: .degrees(to - 90),
            clockwise: false
        )
        return path
    }
}

/// 그랄 한 줄. progress가 0 → 1로 가며 링 바깥 끝에서 안쪽으로 차오른다(1이면 링 굵기 전체).
private struct RingStripe: Shape {
    let from: Double
    let to: Double
    let radius: CGFloat
    let width: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let filled = width * min(max(progress, 0), 1)
        guard filled > 0 else { return Path() }
        return RingArc(from: from, to: to, radius: radius + (width - filled) / 2)
            .path(in: rect)
            .strokedPath(StrokeStyle(lineWidth: filled))
    }
}

// MARK: - Motion

/// 세션 첫 MY·띠 바꾼 직후의 등장(웅크렸다 도는) 움직임과, 사진을 눌렀을 때의 다시 보기 움직임(#338).
private enum SpinKind {
    case entrance
    case replay
}

/// 링만 돌린다. time을 선형으로 움직이고 각도는 곡선으로 매 프레임 계산한다.
private struct SpinRotation: ViewModifier, Animatable {
    var time: Double
    let kind: SpinKind
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(Motion.frame(at: time, kind: kind).angle))
    }
}

/// 사진과 링을 함께 키우고 줄인다.
private struct SpinScale: ViewModifier, Animatable {
    var time: Double
    let kind: SpinKind
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content.scaleEffect(Motion.frame(at: time, kind: kind).scale)
    }
}

/// 등장 움직임 — 시안(belt-kids6) `spinCore`를 그대로 옮겼다. 시간 단위는 ms.
/// 0~0.14초 웅크림 → 1초까지 링이 천천히 출발해 빨라졌다 천천히 두 바퀴 → 제자리를 6° 지나쳤다 통통 멈춤.
/// 다시 보기(#338)는 도는 곡선·시간이 같고, 웅크림 없이 가장 빨리 돌 때 1.12배까지 커졌다 돌아온다.
private enum Motion {
    static let total: Double = 1400
    static let firstPhase: Double = 1000
    static let replayPeakScale: Double = 0.12

    static func frame(at elapsed: Double, kind: SpinKind) -> (angle: Double, scale: Double) {
        guard elapsed < total else { return (0, 1) }
        let angle: Double
        let scale: Double
        if elapsed < firstPhase {
            angle = -720 + 726 * sine(elapsed / firstPhase)
        } else {
            let settle = elapsed - firstPhase
            angle = 6 * exp(-settle / 110) * cos(2 * .pi * settle / 360)
        }
        if kind == .replay, elapsed < firstPhase {
            scale = 1 + replayPeakScale * sin(.pi * elapsed / firstPhase)
        } else if elapsed < 140 {
            scale = 1 - 0.06 * sin(.pi / 2 * elapsed / 140)
        } else if elapsed < firstPhase {
            let progress = (elapsed - 140) / (firstPhase - 140)
            scale = 0.94 + 0.14 * sin(.pi * progress) + 0.06 * progress
        } else {
            let settle = elapsed - firstPhase
            scale = 1 - 0.05 * exp(-settle / 110) * sin(2 * .pi * settle / 300)
        }
        return (angle, scale)
    }

    private static func sine(_ fraction: Double) -> Double {
        -(cos(.pi * fraction) - 1) / 2
    }
}

// MARK: - Entrance Motion (shared)

/// 등장 움직임(웅크렸다 두 바퀴 돌고 통통 멈춤)을 다른 장면에서 같은 곡선으로 쓴다 — 승급 축하 장면.
/// time(ms)을 0 → `MyBeltRingEntrance.total`로 선형 애니메이션하면 된다.
enum MyBeltRingEntrance {
    static let total = Motion.total
}

extension View {
    /// 링만 돌린다.
    func myBeltRingEntranceRotation(time: Double) -> some View {
        modifier(SpinRotation(time: time, kind: .entrance))
    }

    /// 사진과 링을 함께 웅크렸다 편다.
    func myBeltRingEntranceScale(time: Double) -> some View {
        modifier(SpinScale(time: time, kind: .entrance))
    }
}

// MARK: - Preview

#Preview("MyBeltRingView") {
    HStack(spacing: 24) {
        MyBeltRingView(beltRank: .white, beltStripe: .two) { Color.gray }
        MyBeltRingView(beltRank: .blue, beltStripe: .four) { Color.gray }
        MyBeltRingView(beltRank: nil, beltStripe: nil) { Color.gray }
    }
    .padding(40)
    .background(Color.component.myBelt.blue)
}
