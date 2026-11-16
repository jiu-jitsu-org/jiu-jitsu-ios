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
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinToken = 0
    /// 움직임 경과 시간(ms). 0 → total로 선형 애니메이션하고, 곡선은 매 프레임 Motion.frame이 계산한다.
    @State private var spinTime = Motion.total

    var body: some View {
        ZStack {
            content
                .frame(width: Ring.photo, height: Ring.photo)
                .clipShape(Circle())

            ring
                .modifier(SpinRotation(time: spinTime))
                .allowsHitTesting(false)
        }
        .frame(width: Ring.box, height: Ring.box)
        .modifier(SpinScale(time: spinTime))
        .onChange(of: entranceTrigger) { _, _ in
            guard !reduceMotion else { return }
            spinToken += 1
        }
        .task(id: spinToken) {
            guard spinToken > 0 else { return }
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { spinTime = 0 }
            // 0으로 돌린 프레임이 한 번 그려진 뒤에 출발해야 처음부터 돈다.
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: Motion.total / 1000)) { spinTime = Motion.total }
        }
    }

    // MARK: - Ring

    @ViewBuilder
    private var ring: some View {
        if let beltRank {
            ZStack {
                Circle()
                    .inset(by: Ring.box / 2 - (Ring.radius - 0.5))
                    .stroke(haloColor(beltRank), lineWidth: Ring.width + Ring.gap + 3)
                Circle()
                    .inset(by: Ring.box / 2 - Ring.radius)
                    .stroke(beltRank.beltSurfaceColor, lineWidth: Ring.width)
                RingArc(from: Ring.barCenter - Ring.barWidth / 2, to: Ring.barCenter + Ring.barWidth / 2)
                    .stroke(
                        beltRank == .black ? Color.component.myBelt.blackRankBar : Color.component.myBelt.ringRankBar,
                        lineWidth: Ring.width
                    )
                ForEach(0..<(beltStripe?.count ?? 0), id: \.self) { index in
                    let count = Double(beltStripe?.count ?? 0)
                    let center = Ring.barCenter + (Double(index) - (count - 1) / 2) * Ring.markPitchDegrees
                    RingArc(from: center - Ring.markDegrees / 2, to: center + Ring.markDegrees / 2)
                        .stroke(Color.component.myBelt.stripe, lineWidth: Ring.width)
                }
            }
            .frame(width: Ring.box, height: Ring.box)
        } else {
            Circle()
                .inset(by: Ring.box / 2 - Ring.radius)
                .stroke(
                    Color.component.myBelt.noBeltRing,
                    style: StrokeStyle(lineWidth: Ring.width, dash: [Ring.noBeltDash / 2, Ring.noBeltDash / 2])
                )
                .frame(width: Ring.box, height: Ring.box)
        }
    }

    private func haloColor(_ beltRank: BeltRank) -> Color {
        beltRank.isLightBelt
            ? Color.component.myBelt.lightInk.opacity(Ring.haloOpacity * 0.24)
            : Color.primitive.bw.trueWhite.opacity(Ring.haloOpacity)
    }
}

// MARK: - Ring Metrics

enum MyBeltRing {
    /// 사진 + 틈 + 링 바깥 지름. 헤더 레이아웃은 이 크기를 차지한다(흰 테는 3pt씩 바깥으로 번진다).
    static let box: CGFloat = Ring.box
}

private enum Ring {
    static let photo: CGFloat = 90
    static let gap: CGFloat = 4
    static let width: CGFloat = 7
    static let mark: CGFloat = 3.5
    static let haloOpacity: Double = 0.7
    static let box: CGFloat = photo + 2 * (gap + width)
    /// 링 중심선 반지름
    static let radius: CGFloat = photo / 2 + gap + width / 2
    static let barCenter: Double = 135
    static let barWidth: Double = 44
    static let markDegrees = Double(mark / (2 * .pi * radius)) * 360
    static let markPitchDegrees = Double(mark * 2.4 / (2 * .pi * radius)) * 360
    /// 띠 없음 점선 한 칸(선+틈) — 둘레에 딱 나눠떨어지게
    static let noBeltDash: CGFloat = {
        let circumference = 2 * .pi * radius
        return circumference / (circumference / 12).rounded()
    }()
}

/// 12시 = 0°, 시계 방향 각도로 그린 원호. 굵기는 stroke로 준다.
private struct RingArc: Shape {
    let from: Double
    let to: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: Ring.radius,
            startAngle: .degrees(from - 90),
            endAngle: .degrees(to - 90),
            clockwise: false
        )
        return path
    }
}

// MARK: - Motion

/// 링만 돌린다. time을 선형으로 움직이고 각도는 곡선으로 매 프레임 계산한다.
private struct SpinRotation: ViewModifier, Animatable {
    var time: Double
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(Motion.frame(at: time).angle))
    }
}

/// 사진과 링을 함께 키우고 줄인다.
private struct SpinScale: ViewModifier, Animatable {
    var time: Double
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content.scaleEffect(Motion.frame(at: time).scale)
    }
}

/// 등장 움직임 — 시안(belt-kids6) `spinCore`를 그대로 옮겼다. 시간 단위는 ms.
/// 0~0.14초 웅크림 → 1초까지 링이 천천히 출발해 빨라졌다 천천히 두 바퀴 → 제자리를 6° 지나쳤다 통통 멈춤.
private enum Motion {
    static let total: Double = 1400
    static let firstPhase: Double = 1000

    static func frame(at elapsed: Double) -> (angle: Double, scale: Double) {
        guard elapsed < total else { return (0, 1) }
        let angle: Double
        let scale: Double
        if elapsed < firstPhase {
            angle = -720 + 726 * sine(elapsed / firstPhase)
        } else {
            let settle = elapsed - firstPhase
            angle = 6 * exp(-settle / 110) * cos(2 * .pi * settle / 360)
        }
        if elapsed < 140 {
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
