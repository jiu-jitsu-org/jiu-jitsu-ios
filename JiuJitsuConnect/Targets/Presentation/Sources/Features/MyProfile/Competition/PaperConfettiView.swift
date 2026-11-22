import SwiftUI
import DesignSystem

/// 완료 화면 뒤에서 퍼진 뒤 계속 내리는 종이 꽃가루(#220).
///
/// 정해진 경로로 그리면 도형이 미끄러지는 것처럼 보여서, 조각마다 무게·공기 저항·팔랑임·뒤집힘을 계산한다.
/// `isOneShot`이면 한 번만 터지고, 화면 밖으로 나간 조각은 다시 내려오지 않아 다 나가면 멈춘다(승급 축하).
struct PaperConfettiView: View {
    let startDelay: TimeInterval
    /// 조각 색. 비우면 다섯 띠 색.
    var colors: [Color]?
    /// 터지는 자리(이 뷰 좌표). 비우면 가운데 가슴께(높이 42%).
    var burstOrigin: CGPoint?
    var isOneShot = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var simulation = PaperConfettiSimulation()
    /// 한 번 터진 조각이 모두 화면 밖으로 나감 — 더 그리지 않는다.
    @State private var isFinished = false

    private var pieceColors: [Color] {
        if let colors, !colors.isEmpty { return colors }
        let belt = Color.component.beltSelectButton.belt
        return [belt.white, belt.blue, belt.purple, belt.brown, belt.black]
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let colors = pieceColors

            // 계속 내리므로 화면에 오래 머물러도 배터리를 덜 쓰게 120Hz 기기에서도 60번까지만 그린다.
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion || isFinished || scenePhase != .active)) { context in
                let pieces = simulation.pieces(
                    at: context.date,
                    size: size,
                    startDelay: startDelay,
                    colorCount: colors.count,
                    settlesImmediately: reduceMotion,
                    origin: burstOrigin,
                    isOneShot: isOneShot
                )

                Canvas { graphics, _ in
                    for piece in pieces {
                        Self.draw(piece, color: colors[piece.colorIndex], in: graphics)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            guard isOneShot else { return }
            // 조각이 다 나갔는지 가끔만 살핀다. 다 나가면 타임라인을 멈춘다.
            while !Task.isCancelled, !simulation.isFinished {
                try? await Task.sleep(for: .milliseconds(500))
            }
            isFinished = simulation.isFinished
        }
    }

    private static func draw(_ piece: PaperConfettiSimulation.Piece, color: Color, in graphics: GraphicsContext) {
        let flip = cos(piece.flip)
        // 완전히 옆을 볼 때도 종이 두께만큼은 보인다.
        let foreshortening = max(0.13, abs(flip))
        let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)

        var context = graphics
        context.translateBy(x: piece.x, y: piece.y)
        context.rotate(by: .radians(piece.spin))
        context.scaleBy(x: 1, y: foreshortening)
        context.fill(Path(rect), with: .color(color))
        // 뒷면은 살짝 어둡고, 기울수록 그늘이 진다.
        let shade = (flip < 0 ? 0.14 : 0.02) + (1 - foreshortening) * 0.16
        context.fill(Path(rect), with: .color(Color.primitive.bw.black.opacity(shade)))
    }
}

/// 조각들의 물리 계산. 뷰가 다시 그려져도 이어지도록 참조 타입으로 둔다.
@MainActor
final class PaperConfettiSimulation {
    struct Piece: Sendable {
        var x: CGFloat
        var y: CGFloat
        var velocityX: CGFloat
        var velocityY: CGFloat
        let mass: CGFloat
        let width: CGFloat
        let height: CGFloat
        var flip: CGFloat
        var flipSpeed: CGFloat
        let baseFlipSpeed: CGFloat
        var spin: CGFloat
        let spinSpeed: CGFloat
        var sway: CGFloat
        let swaySpeed: CGFloat
        let colorIndex: Int
    }

    // 색종이 정도의 무게. 화면 320pt를 약 3.9초에 내려온다.
    private enum Physics {
        // 높이 320pt 무대에서 맞춘 값. 무대가 커지면 터지는 거리와 조각 수를 높이에 비례해 늘려 같은 모습으로 무대 전체에 퍼진다(#235).
        static let pieceCount = 40
        static let referenceHeight: CGFloat = 320
        static let gravity: CGFloat = 380
        static let drag: CGFloat = 5.5
        static let swayForce: CGFloat = 175
        static let stepInterval: TimeInterval = 1.0 / 120
        static let maxFrameInterval: TimeInterval = 0.05
    }

    private var pieces: [Piece] = []
    private var size: CGSize = .zero
    private var createdAt: Date?
    private var lastDate: Date?
    private var unsimulated: TimeInterval = 0
    private var origin: CGPoint?
    private var isOneShot = false
    private var hasBurst = false

    /// 한 번만 터지는 꽃가루가 터진 뒤 모두 화면 밖으로 나감.
    var isFinished: Bool { isOneShot && hasBurst && pieces.isEmpty }

    func pieces(
        at date: Date,
        size: CGSize,
        startDelay: TimeInterval,
        colorCount: Int,
        settlesImmediately: Bool,
        origin: CGPoint? = nil,
        isOneShot: Bool = false
    ) -> [Piece] {
        guard size.width > 0, size.height > 0 else { return [] }
        self.size = size
        self.origin = origin
        self.isOneShot = isOneShot

        if settlesImmediately {
            if pieces.isEmpty, !hasBurst {
                burst(colorCount: colorCount)
                for _ in 0..<Int(1.5 / Physics.stepInterval) { step(Physics.stepInterval) }
            }
            return pieces
        }

        let createdAt = self.createdAt ?? date
        self.createdAt = createdAt
        guard date.timeIntervalSince(createdAt) >= startDelay else { return [] }

        if pieces.isEmpty {
            // 한 번만 터지는 꽃가루는 다 나간 뒤 다시 터지지 않는다.
            if isOneShot, hasBurst { return [] }
            burst(colorCount: colorCount)
            lastDate = date
        }
        // 앱이 잠깐 멈췄다 돌아와도 조각이 순간이동하지 않게 한 번에 계산하는 시간을 제한한다.
        unsimulated += min(Physics.maxFrameInterval, date.timeIntervalSince(lastDate ?? date))
        lastDate = date
        while unsimulated >= Physics.stepInterval {
            step(Physics.stepInterval)
            unsimulated -= Physics.stepInterval
        }
        return pieces
    }

    /// 캐릭터 뒤 가슴께에서 사방으로 터진다.
    private func burst(colorCount: Int) {
        // 공기 저항이 같아 터지는 시간은 그대로이고 거리만 늘어난다.
        let scale = max(1, size.height / Physics.referenceHeight)
        let center = origin ?? CGPoint(x: size.width / 2, y: size.height * 0.42)
        hasBurst = true
        pieces = (0..<Int((CGFloat(Physics.pieceCount) * scale).rounded())).map { index in
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let speed = CGFloat.random(in: 260...1000) * scale
            let baseFlipSpeed = CGFloat.random(in: 4...8)
            let direction: CGFloat = Bool.random() ? 1 : -1
            return Piece(
                x: center.x + .random(in: -16...16),
                y: center.y + .random(in: -30...30),
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 190 * scale,
                mass: .random(in: 0.75...1.3),
                width: .random(in: 6...9),
                height: .random(in: 9...13),
                flip: .random(in: 0..<(2 * .pi)),
                flipSpeed: baseFlipSpeed * direction * 2.4,
                baseFlipSpeed: baseFlipSpeed * direction,
                spin: .random(in: 0..<(2 * .pi)),
                spinSpeed: .random(in: -1.6...1.6),
                sway: .random(in: 0..<(2 * .pi)),
                swaySpeed: .random(in: 1.8...3.2),
                colorIndex: index % colorCount
            )
        }
    }

    private func step(_ interval: TimeInterval) {
        let seconds = CGFloat(interval)
        for index in pieces.indices {
            var piece = pieces[index]
            piece.sway += piece.swaySpeed * seconds

            // 면이 정면일수록 공기를 많이 받아 천천히 떨어지고, 흔들리는 끝에서 잠깐 더 느려진다.
            let facing = abs(cos(piece.flip))
            let drag = (Physics.drag / piece.mass) * (0.62 + 0.38 * facing) * (1 + 0.22 * cos(2 * piece.sway))
            piece.velocityX += (Physics.swayForce * sin(piece.sway) - drag * piece.velocityX) * seconds
            piece.velocityY += (Physics.gravity - drag * piece.velocityY) * seconds
            piece.x += piece.velocityX * seconds
            piece.y += piece.velocityY * seconds

            // 터질 때 빠르게 돌던 조각이 공기에 잡히면 원래 속도로 잦아든다.
            let targetFlipSpeed = piece.baseFlipSpeed * (1 + 0.5 * abs(sin(piece.sway)))
            piece.flipSpeed += (targetFlipSpeed - piece.flipSpeed) * min(1, 2.2 * seconds)
            piece.flip += piece.flipSpeed * seconds
            piece.spin += (piece.spinSpeed + piece.velocityX * 0.012) * seconds

            if piece.x < -20 { piece.x = size.width + 20 }
            if piece.x > size.width + 20 { piece.x = -20 }
            // 아래로 나간 조각은 위에서 다시 내려와 꽃가루가 끊이지 않는다. 한 번만 터지는 꽃가루는 다 돈 뒤 걷어낸다.
            if !isOneShot, piece.y > size.height + 16 {
                piece.x = .random(in: 0...size.width)
                piece.y = -.random(in: 12...90)
                piece.velocityX = .random(in: -8...8)
                piece.velocityY = Physics.gravity / (Physics.drag / piece.mass)
                piece.flip = .random(in: 0..<(2 * .pi))
                piece.flipSpeed = piece.baseFlipSpeed
            }
            pieces[index] = piece
        }
        if isOneShot {
            pieces.removeAll { $0.y > size.height + 16 }
        }
    }
}
