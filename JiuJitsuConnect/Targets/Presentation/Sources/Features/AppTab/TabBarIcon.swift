//
//  TabBarIcon.swift
//  Presentation
//

import SwiftUI
import DesignSystem

/// 하단 탭바 아이콘 종류. 모양은 24×24 격자 위의 한 줄짜리 외곽선이다.
enum TabBarIconKind {
    case home
    case competition
    case my
}

/// 하단 탭바 아이콘(#262).
///
/// 탭을 고르면 띠가 테두리를 감듯 외곽선이 위 가운데에서 시작해 시계 방향으로 그려지고,
/// 다 감기면 안쪽이 옅게 차오르며 아이콘이 한 번 살짝 커졌다 자리를 잡는다.
/// 처음부터 골라져 있던 탭(앱 실행 직후)과 '동작 줄이기' 설정에서는 움직임 없이 끝 모습을 보인다.
/// 고른 탭에서 벗어나면 움직임 없이 바로 기본 모습으로 돌아간다.
struct TabBarIcon: View {
    let kind: TabBarIconKind
    let isSelected: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 바뀔 때마다 감기 움직임을 한 번 재생한다
    @State private var wrapCount = 0

    private enum Metrics {
        static let size: CGFloat = 24
        static let unselectedLineWidth: CGFloat = 2
        // 감긴 선이 기본 선보다 조금 도톰해 보이게
        static let selectedLineWidth: CGFloat = 2.3
        // 안쪽은 선 색을 옅게 깔아 선이 주인공으로 남게
        static let selectedFillOpacity: Double = 0.2
    }

    private enum Timing {
        // 외곽선이 한 바퀴 감기는 시간
        static let draw: TimeInterval = 0.9
        // 감기 곡선이 끝에서 오래 늘어져, 눈으로는 이 시점에 다 감긴 것처럼 보인다.
        // 안쪽 채우기와 살짝 커지기는 여기서 시작한다
        static let settleStart: TimeInterval = 0.82
        static let fill: TimeInterval = 0.2
        // 커지기(0.1초) + 스프링으로 돌아오기(0.16초) = 약 0.26초
        static let scaleUp: TimeInterval = 0.1
        static let scaleBack: TimeInterval = 0.16
        static let settleScale: CGFloat = 1.08
    }

    /// 감기 움직임 값. 처음 값과 마지막 값이 모두 '다 감긴 모습'이라
    /// 움직임이 없을 때는 언제나 끝 모습이 보인다.
    private struct WrapPose {
        var progress: CGFloat = 1
        var fillOpacity: Double = Metrics.selectedFillOpacity
        var scale: CGFloat = 1
    }

    var body: some View {
        let shape = TabBarIconShape(kind: kind)
        let selectedColor = Color.component.navibar.selected.icon

        KeyframeAnimator(initialValue: WrapPose(), trigger: wrapCount) { pose in
            Group {
                if isSelected {
                    ZStack {
                        shape
                            .fill(selectedColor.opacity(pose.fillOpacity))
                        shape
                            .trim(from: 0, to: pose.progress)
                            .stroke(
                                selectedColor,
                                style: StrokeStyle(
                                    lineWidth: Metrics.selectedLineWidth,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    }
                    .scaleEffect(pose.scale)
                } else {
                    shape
                        .stroke(
                            Color.component.navibar.unselected.icon,
                            style: StrokeStyle(
                                lineWidth: Metrics.unselectedLineWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                }
            }
            .frame(width: Metrics.size, height: Metrics.size)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                MoveKeyframe(0)
                LinearKeyframe(
                    1,
                    duration: Timing.draw,
                    timingCurve: .bezier(
                        startControlPoint: UnitPoint(x: 0.45, y: 0),
                        endControlPoint: UnitPoint(x: 0.2, y: 1)
                    )
                )
            }
            KeyframeTrack(\.fillOpacity) {
                MoveKeyframe(0)
                LinearKeyframe(0, duration: Timing.settleStart)
                LinearKeyframe(Metrics.selectedFillOpacity, duration: Timing.fill, timingCurve: .easeOut)
            }
            KeyframeTrack(\.scale) {
                MoveKeyframe(1)
                LinearKeyframe(1, duration: Timing.settleStart)
                CubicKeyframe(Timing.settleScale, duration: Timing.scaleUp)
                SpringKeyframe(1, duration: Timing.scaleBack, spring: .bouncy)
            }
        }
        .onChange(of: isSelected) { wasSelected, nowSelected in
            guard !wasSelected, nowSelected, !reduceMotion else { return }
            wrapCount += 1
        }
    }
}

/// 탭바 아이콘 외곽선. 모두 위 가운데(12, 4 근처)에서 시작해 화면 기준 시계 방향으로 돈다.
/// `trim`으로 그려지는 순서가 곧 이 경로의 순서이므로 점 순서를 바꾸지 않는다.
struct TabBarIconShape: Shape {
    let kind: TabBarIconKind

    /// 디자인 격자 한 변
    private static let gridSize: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.gridSize
        let transform = CGAffineTransform(
            translationX: rect.midX - Self.gridSize * scale / 2,
            y: rect.midY - Self.gridSize * scale / 2
        )
        .scaledBy(x: scale, y: scale)
        return gridPath.applying(transform)
    }

    private var gridPath: Path {
        switch kind {
        case .home: Self.home
        case .competition: Self.competition
        case .my: Self.my
        }
    }

    // MARK: - 24×24 격자 경로 (디자인 SVG를 그대로 옮김)

    /// 둥근 지붕 집
    private static let home = Path { p in
        p.move(to: pt(12, 4.44))
        p.addCurve(to: pt(13.78, 5.12), control1: pt(12.62, 4.44), control2: pt(13.25, 4.66))
        p.addLine(to: pt(18.12, 8.82))
        p.addCurve(to: pt(19.5, 11.82), control1: pt(18.95, 9.53), control2: pt(19.5, 10.73))
        p.addLine(to: pt(19.5, 18.42))
        p.addCurve(to: pt(17.42, 20.5), control1: pt(19.5, 19.67), control2: pt(18.67, 20.5))
        p.addLine(to: pt(6.58, 20.5))
        p.addCurve(to: pt(4.5, 18.42), control1: pt(5.33, 20.5), control2: pt(4.5, 19.67))
        p.addLine(to: pt(4.5, 11.82))
        p.addCurve(to: pt(5.88, 8.82), control1: pt(4.5, 10.73), control2: pt(5.05, 9.53))
        p.addLine(to: pt(10.22, 5.12))
        p.addCurve(to: pt(12, 4.44), control1: pt(10.75, 4.66), control2: pt(11.38, 4.44))
        p.closeSubpath()
    }

    /// 트로피. 손잡이는 같은 곡선을 나갔다 되돌아와 가는 한 줄로 보인다
    private static let competition = Path { p in
        p.move(to: pt(12, 4))
        p.addLine(to: pt(15.04, 4))
        p.addQuadCurve(to: pt(16.6, 5.56), control: pt(16.6, 4))
        p.addLine(to: pt(16.6, 5.6))
        // 오른쪽 손잡이: 나갔다가
        p.addCurve(to: pt(20.4, 8.2), control1: pt(18.8, 5.2), control2: pt(20.4, 6.2))
        p.addCurve(to: pt(17.6, 11.1), control1: pt(20.4, 10.2), control2: pt(19, 11.2))
        // 같은 곡선으로 되돌아온다
        p.addCurve(to: pt(20.4, 8.2), control1: pt(19, 11.2), control2: pt(20.4, 10.2))
        p.addCurve(to: pt(16.6, 5.6), control1: pt(20.4, 6.2), control2: pt(18.8, 5.2))
        p.addLine(to: pt(16.6, 9.4))
        p.addCurve(to: pt(13.5, 15.6), control1: pt(16.4, 12.8), control2: pt(15, 14.9))
        p.addLine(to: pt(13.5, 17.6))
        p.addCurve(to: pt(14.5, 18.6), control1: pt(13.5, 18.2), control2: pt(13.9, 18.6))
        p.addLine(to: pt(15.4, 18.6))
        p.addQuadCurve(to: pt(16.4, 19.6), control: pt(16.4, 18.6))
        p.addLine(to: pt(16.4, 20.2))
        p.addQuadCurve(to: pt(15.4, 21.2), control: pt(16.4, 21.2))
        p.addLine(to: pt(8.6, 21.2))
        p.addQuadCurve(to: pt(7.6, 20.2), control: pt(7.6, 21.2))
        p.addLine(to: pt(7.6, 19.6))
        p.addQuadCurve(to: pt(8.6, 18.6), control: pt(7.6, 18.6))
        p.addLine(to: pt(9.5, 18.6))
        p.addCurve(to: pt(10.5, 17.6), control1: pt(10.1, 18.6), control2: pt(10.5, 18.2))
        p.addLine(to: pt(10.5, 15.6))
        p.addCurve(to: pt(7.4, 9.4), control1: pt(9, 14.9), control2: pt(7.6, 12.8))
        p.addLine(to: pt(7.4, 5.6))
        // 왼쪽 손잡이: 나갔다가
        p.addCurve(to: pt(3.6, 8.2), control1: pt(5.2, 5.2), control2: pt(3.6, 6.2))
        p.addCurve(to: pt(6.4, 11.1), control1: pt(3.6, 10.2), control2: pt(5, 11.2))
        // 같은 곡선으로 되돌아온다
        p.addCurve(to: pt(3.6, 8.2), control1: pt(5, 11.2), control2: pt(3.6, 10.2))
        p.addCurve(to: pt(7.4, 5.6), control1: pt(3.6, 6.2), control2: pt(5.2, 5.2))
        p.addLine(to: pt(7.4, 5.56))
        p.addQuadCurve(to: pt(8.96, 4), control: pt(7.4, 4))
        p.closeSubpath()
    }

    /// 머리에서 어깨로 한 줄로 이어지는 사람
    private static let my = Path { p in
        // 머리는 중심 (12, 8.4), 반지름 4인 원의 일부다.
        // y가 아래로 커지는 좌표라 clockwise: false가 화면에서는 시계 방향이다.
        let headCenter = pt(12, 8.4)
        let headRadius: CGFloat = 4
        p.move(to: pt(12, 4.4))
        // 위(-90°)에서 오른쪽을 돌아 목 오른쪽(60°, ≈(14, 11.86))까지
        p.addArc(
            center: headCenter,
            radius: headRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(60),
            clockwise: false
        )
        p.addCurve(to: pt(19.4, 18), control1: pt(14.5, 13.1), control2: pt(19.4, 13))
        p.addLine(to: pt(19.4, 19.82))
        p.addQuadCurve(to: pt(18.62, 20.6), control: pt(19.4, 20.6))
        p.addLine(to: pt(5.38, 20.6))
        p.addQuadCurve(to: pt(4.6, 19.82), control: pt(4.6, 20.6))
        p.addLine(to: pt(4.6, 18))
        p.addCurve(to: pt(10, 11.86), control1: pt(4.6, 13), control2: pt(9.5, 13.1))
        // 목 왼쪽(120°, ≈(10, 11.86))에서 왼쪽을 돌아 위(270°)로
        p.addArc(
            center: headCenter,
            radius: headRadius,
            startAngle: .degrees(120),
            endAngle: .degrees(270),
            clockwise: false
        )
        p.closeSubpath()
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selected: TabBarIconKind = .home
    let kinds: [TabBarIconKind] = [.home, .competition, .my]

    HStack(spacing: 32) {
        ForEach(kinds, id: \.self) { kind in
            Button {
                selected = kind
            } label: {
                TabBarIcon(kind: kind, isSelected: selected == kind)
            }
            .buttonStyle(.plain)
        }
    }
    .scaleEffect(3)
}
