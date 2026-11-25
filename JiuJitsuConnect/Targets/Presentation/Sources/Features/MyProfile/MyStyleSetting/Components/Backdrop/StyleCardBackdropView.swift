//
//  StyleCardBackdropView.swift
//  Presentation
//
//  최애 기술 카드 앞면 바탕(#495) — 고른 시안을 기술 · 띠에 맞게 그린다.
//

import SwiftUI
import DesignSystem
import Domain

/// 카드 앞면 바탕. 카드(262×394) 좌표로 그리고, 다른 크기면 비율대로 늘린다.
struct StyleCardBackdropView: View {
    let backdrop: StyleCardBackdrop
    let impact: StyleImpact
    let colors: StyleCardBackdropColors
    /// 잔상 시안에 쓰는 캐릭터 그림
    let poseImage: Image

    var body: some View {
        Canvas { context, size in
            var scaled = context
            scaled.scaleBy(x: size.width / BackdropPainter.cardSize.width, y: size.height / BackdropPainter.cardSize.height)
            var painter = BackdropPainter(context: scaled, rng: SeededRandom(seed: seed))
            painter.draw(backdrop, impact: impact, colors: colors, poseImage: poseImage)
        }
        .accessibilityHidden(true)
    }

    /// 시안 페이지와 같은 씨앗 — 같은 기술이면 늘 같은 파편 배치
    private var seed: Int {
        switch backdrop {
        case .impact: return impact.seed * 97 + 13
        case .clash: return impact.seed * 53 + 7
        case .shatter: return impact.seed * 31 + 5
        case .soundEffect: return impact.seed * 71 + 3
        case .echoImpact: return impact.seed * 19 + 11
        case .scoreImpact: return impact.seed * 23 + 17
        case .scoreboard, .echo: return 29
        }
    }
}

// MARK: - 시안별 그림

extension BackdropPainter {
    mutating func draw(_ backdrop: StyleCardBackdrop, impact: StyleImpact, colors: StyleCardBackdropColors, poseImage: Image) {
        switch backdrop {
        case .impact: drawImpact(impact, colors: colors)
        case .clash: drawClash(impact, colors: colors)
        case .shatter: drawShatter(impact, colors: colors)
        case .soundEffect: drawSoundEffect(impact, colors: colors)
        case .echoImpact: drawEchoImpact(impact, colors: colors, poseImage: poseImage)
        case .scoreImpact: drawScoreImpact(impact, colors: colors)
        case .scoreboard: drawScoreboard(impact, colors: colors)
        case .echo: drawEcho(colors: colors, poseImage: poseImage)
        }
    }

    /// 글자 자리 위쪽에서 흐려지는 층에 그린다
    mutating func fading(_ draw: (inout BackdropPainter) -> Void) {
        var carried = rng
        context.fadingAtTextArea { layer in
            var inner = BackdropPainter(context: layer, rng: carried)
            draw(&inner)
            carried = inner.rng
        }
        rng = carried
    }

    // MARK: 1 충격

    private mutating func drawImpact(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        fillCard(top: colors.base, bottom: colors.deep)
        glow(at: CGPoint(x: 131, y: 116), radius: 120, color: colors.glow, opacity: colors.glowOpacity)
        fading { $0.impactScene(impact, colors: colors) }
    }

    // MARK: 2 맞부딪힘

    private mutating func drawClash(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let center = CGPoint(x: 131, y: 112)
        let theta = impact.clashDegrees * BackdropShape.degree
        let normal = CGVector(dx: cos(theta), dy: sin(theta)), along = CGVector(dx: -sin(theta), dy: cos(theta))
        fillCard(top: colors.opponent, bottom: colors.opponentDeep)

        var seam: [CGPoint] = []
        for step in -9...9 {
            let distance = CGFloat(step) * 34
            let offset = (step % 2 != 0 ? 1 : -1) * (14 + rng.next() * 10)
            seam.append(CGPoint(x: center.x + along.dx * distance + normal.dx * offset, y: center.y + along.dy * distance + normal.dy * offset))
        }
        let shifted: (CGPoint, CGFloat) -> CGPoint = { CGPoint(x: $0.x - normal.dx * $1, y: $0.y - normal.dy * $1) }
        if let first = seam.first, let last = seam.last {
            let mine = seam + [shifted(last, 700), shifted(first, 700)]
            context.fill(
                BackdropShape.polygon(mine),
                with: .linearGradient(Gradient(colors: [colors.base, colors.deep]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 394))
            )
        }
        fill(seam + seam.reversed().map { shifted($0, 22) }, colors.mid, opacity: 0.45)

        fading { painter in
            painter.stroke(seam, colors.glow, width: 3)
            painter.blast(center, count: 13, radius: 70, SpikyOptions(dir: atan2(along.dy, along.dx), stretch: 0.9, jitter: 0.6), colors: [colors.light, colors.glow, colors.glow])
            painter.fillSpiky(center, count: 10, inner: 20, outer: 70, SpikyOptions(dir: atan2(-along.dy, -along.dx), stretch: 0.9), color: colors.glow, opacity: 0.8)
            for _ in 0..<18 {
                let side: CGFloat = painter.rng.next() < 0.5 ? 1 : -1
                let angle = atan2(along.dy * side, along.dx * side) + (painter.rng.next() - 0.5) * 0.9, distance = 40 + painter.rng.next() * 120
                let length = 8 + painter.rng.next() * 14, width = 4 + painter.rng.next() * 4
                let color = painter.rng.pick([colors.glow, colors.light, colors.opponentSpark, colors.accent]), trail = 12 + painter.rng.next() * 20
                painter.shard(BackdropShape.point(center, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
            }
        }
        context.fill(
            Path(CGRect(x: 0, y: 190, width: 262, height: 204)),
            with: .linearGradient(Gradient(colors: [colors.deep.opacity(0), colors.deep]), startPoint: CGPoint(x: 0, y: 190), endPoint: CGPoint(x: 0, y: 226))
        )
        glow(at: CGPoint(x: 131, y: 116), radius: 110, color: colors.glow, opacity: colors.glowOpacity * 0.6)
    }

    // MARK: 3 파편

    private mutating func drawShatter(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let at: CGPoint
        switch impact.kind {
        case .slam: at = CGPoint(x: 150, y: 170)
        case .press: at = CGPoint(x: 131, y: 40)
        default: at = impact.point
        }
        let length = max(hypot(impact.move.dx, impact.move.dy), 1)
        let moveX = impact.move.dx / length, moveY = impact.move.dy / length
        let lineColor = colors.mid.mix(with: colors.deep, by: 0.35)
        fillCard(colors.tint)

        let spokes = 12
        let rings: [CGFloat] = [0, 30, 64, 108, 160, 240]
        let angles = (0..<spokes).map { CGFloat($0) / CGFloat(spokes) * .pi * 2 + (rng.next() - 0.5) * 0.3 }
        var radii: [[CGFloat]] = []
        for (ring, base) in rings.enumerated() {
            radii.append(angles.map { _ in ring == 0 ? 0 : base * (0.85 + rng.next() * 0.3) })
        }
        let corner: (Int, Int) -> CGPoint = { ring, spoke in
            let index = (spoke + spokes) % spokes
            return BackdropShape.point(at, radii[ring][index], angles[index])
        }

        fading { painter in
            for ring in 0..<(rings.count - 1) {
                for spoke in 0..<spokes {
                    let cell = ring == 0
                        ? [corner(0, spoke), corner(1, spoke), corner(1, spoke + 1)]
                        : [corner(ring, spoke), corner(ring + 1, spoke), corner(ring + 1, spoke + 1), corner(ring, spoke + 1)]
                    let middle = angles[spoke] + .pi / CGFloat(spokes)
                    let ux = cos(middle), uy = sin(middle), alongMove = ux * moveX + uy * moveY
                    let flies = ring <= 1
                        || (ring == 2 && alongMove > 0.2 && painter.rng.next() < 0.7)
                        || (ring == 3 && alongMove > 0.6 && painter.rng.next() < 0.5)
                    let fillColor = painter.rng.pick([colors.soft, colors.strap, Color.white, colors.soft])
                    let path = BackdropShape.polygon(cell)
                    guard flies else {
                        painter.context.fill(path, with: .color(fillColor.opacity(ring > 3 ? 0.55 : 0.9)))
                        painter.context.stroke(path, with: .color(lineColor), style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
                        continue
                    }
                    let push = 16 + CGFloat(ring) * 14 + painter.rng.next() * 20
                    guard ring != 0 else { continue }
                    let centroid = CGPoint(x: cell.map(\.x).reduce(0, +) / CGFloat(cell.count), y: cell.map(\.y).reduce(0, +) / CGFloat(cell.count))
                    let turn = (painter.rng.next() - 0.5) * 40
                    var moved = painter.context
                    moved.translateBy(x: (ux * 0.5 + moveX * 0.8) * push, y: (uy * 0.5 + moveY * 0.8) * push)
                    moved.translateBy(x: centroid.x, y: centroid.y)
                    moved.rotate(by: .degrees(turn))
                    moved.scaleBy(x: 0.8, y: 0.8)
                    moved.translateBy(x: -centroid.x, y: -centroid.y)
                    moved.fill(path, with: .color(fillColor))
                    moved.stroke(path, with: .color(lineColor), style: StrokeStyle(lineWidth: 1.3 / 0.8, lineJoin: .round))
                }
            }
            painter.fillSpiky(at, count: 12, inner: 14, outer: 44, color: .white)
            for _ in 0..<8 {
                let angle = atan2(moveY, moveX) + (painter.rng.next() - 0.5) * 1.6, distance = 70 + painter.rng.next() * 90
                let trailLength = 18 + painter.rng.next() * 20
                painter.fill(BackdropShape.trail(BackdropShape.point(at, distance, angle), length: trailLength, angle: angle, width: 1.4), lineColor, opacity: 0.5)
            }
        }
    }

    // MARK: 4 의성어

    private mutating func drawSoundEffect(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let spot = impact.soundEffectPoint
        fillCard(top: colors.base, bottom: colors.deep)
        glow(at: CGPoint(x: 131, y: 120), radius: 110, color: colors.glow, opacity: colors.glowOpacity)
        fading { painter in
            let burstCenter = CGPoint(x: spot.x, y: spot.y + 10)
            painter.fillSpiky(burstCenter, count: 14, inner: 30, outer: 84, SpikyOptions(jitter: 0.7, scaleY: 0.8), color: colors.mid)
            painter.fillSpiky(CGPoint(x: spot.x, y: spot.y + 8), count: 12, inner: 24, outer: 60, SpikyOptions(jitter: 0.6, scaleY: 0.75), color: colors.light)
            for _ in 0..<14 {
                let angle = painter.rng.next() * .pi * 2, distance = 66 + painter.rng.next() * 70
                let point = CGPoint(x: spot.x + cos(angle) * distance, y: spot.y + 10 + sin(angle) * distance * 0.8)
                let length = 8 + painter.rng.next() * 14, width = 4 + painter.rng.next() * 4
                let color = painter.rng.pick([colors.glow, colors.light, colors.strap, colors.accent]), trail = 10 + painter.rng.next() * 16
                painter.shard(point, length: length, width: width, angle: angle, color: color, trail: trail)
            }
        }
        let size: CGFloat = impact.soundEffect.count > 3 ? 40 : 46
        let font = Font.cookieRun.custom(weight: .black, size: size)
        var turned = context
        turned.translateBy(x: spot.x, y: spot.y)
        turned.rotate(by: .degrees(impact.soundEffectDegrees))
        let word = impact.soundEffect
        turned.draw(Text(word).font(font).foregroundStyle(colors.deep), at: CGPoint(x: 3, y: 5))
        for step in 0..<16 {
            let angle = CGFloat(step) / 16 * .pi * 2
            turned.draw(Text(word).font(font).foregroundStyle(colors.deep), at: CGPoint(x: cos(angle) * 3, y: sin(angle) * 3))
        }
        turned.draw(Text(word).font(font).foregroundStyle(Color.white), at: .zero)
    }

    // MARK: 5 잔상 충격

    private mutating func drawEchoImpact(_ impact: StyleImpact, colors: StyleCardBackdropColors, poseImage: Image) {
        let length = max(hypot(impact.move.dx, impact.move.dy), 1)
        let moveX = impact.move.dx / length, moveY = impact.move.dy / length, heading = atan2(moveY, moveX)
        let at: CGPoint
        switch impact.kind {
        case .slam: at = CGPoint(x: 176, y: 160)
        case .press: at = CGPoint(x: 131, y: 150)
        default: at = impact.point
        }
        fillCard(top: colors.base, bottom: colors.deep)
        glow(at: at, radius: 120, color: colors.glow, opacity: colors.glowOpacity)
        fading { painter in
            for _ in 0..<10 {
                let offset = (painter.rng.next() - 0.5) * 180, streak = 40 + painter.rng.next() * 80
                let startX = 131 - moveX * (40 + painter.rng.next() * 40) - moveY * offset
                let startY = 112 - moveY * (40 + painter.rng.next() * 40) + moveX * offset
                let width = 1.5 + painter.rng.next() * 1.5, opacity = 0.15 + painter.rng.next() * 0.3
                painter.stroke([CGPoint(x: startX, y: startY), CGPoint(x: startX - moveX * streak, y: startY - moveY * streak)], colors.light, width: width, opacity: opacity)
            }
            for (index, color, opacity) in [(3, colors.mid, 0.3), (2, colors.mid, 0.45), (1, colors.light, 0.6)] {
                let rect = CGRect(x: 23 - moveX * CGFloat(index) * 15, y: -moveY * CGFloat(index) * 12, width: 216, height: 216)
                painter.tinted(poseImage, in: rect, color: color, opacity: opacity)
            }
            painter.arcs(at, radius: 50, scaleY: 1, from: heading - 1.1, to: heading + 1.1, segments: 2, color: colors.light, width: 2.6, opacity: 0.8)
            painter.arcs(at, radius: 82, scaleY: 1, from: heading - 1, to: heading + 1, segments: 3, color: colors.light, width: 2, opacity: 0.5)
            painter.blast(at, count: 12, radius: 70, SpikyOptions(dir: heading, stretch: 0.8, jitter: 0.6), colors: [colors.light, colors.glow, colors.glow])
            for _ in 0..<12 {
                let angle = heading + (painter.rng.next() - 0.5) * 2, distance = 50 + painter.rng.next() * 90
                let length = 8 + painter.rng.next() * 14, width = 4 + painter.rng.next() * 4
                let color = painter.rng.pick([colors.glow, colors.light, colors.strap, colors.accent]), trail = 12 + painter.rng.next() * 18
                painter.shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
            }
        }
    }

    // MARK: 6 점수 충격

    private mutating func drawScoreImpact(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let score = impact.score
        let size: CGFloat = score.count > 2 ? 100 : 156, baseline: CGFloat = score.count > 2 ? 150 : 172
        let center = CGPoint(x: 131, y: 116)
        fillCard(colors.deep)
        var outlineRandom = SeededRandom(seed: impact.seed * 23 + 17)
        let outline = BackdropShape.spiky(center, count: 13, inner: 40, outer: 98, rng: &outlineRandom, SpikyOptions(jitter: 0.55))
        fading { painter in
            painter.fillSpiky(center, count: 14, inner: 46, outer: 128, SpikyOptions(jitter: 0.6), color: colors.base)
            painter.fillSpiky(center, count: 13, inner: 40, outer: 98, SpikyOptions(jitter: 0.55), color: colors.mid, opacity: 0.9)
            painter.stroke(outline, colors.light, width: 1.5, opacity: 0.7, closed: true)
            for _ in 0..<16 {
                let angle = painter.rng.next() * .pi * 2, distance = 96 + painter.rng.next() * 60
                let length = 9 + painter.rng.next() * 14, width = 4 + painter.rng.next() * 4
                let color = painter.rng.pick([colors.glow, colors.light, colors.accent]), trail = 14 + painter.rng.next() * 16
                painter.shard(BackdropShape.point(center, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
            }
            painter.ledText(score, size: size, center: CGPoint(x: 131, y: baseline - size * 0.36), glowOpacity: 0.55)
        }
        scoreboardChrome(colors: colors, showsPenalty: false)
    }

    // MARK: E 점수판

    private mutating func drawScoreboard(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let score = impact.score
        let size: CGFloat = score.count > 2 ? 104 : 168, baseline: CGFloat = score.count > 2 ? 160 : 186
        fillCard(colors.deep)
        context.fill(Self.dotGrid(height: 216, radius: 1.9), with: .color(.white.opacity(0.05)))
        ledText(score, size: size, center: CGPoint(x: 131, y: baseline - size * 0.36), glowOpacity: 0.5)
        glow(at: CGPoint(x: 131, y: 120), radius: 120, color: colors.glow, opacity: colors.glowOpacity)
        scoreboardChrome(colors: colors, showsPenalty: true)
        context.fill(Path(CGRect(x: 24, y: 204, width: 214, height: 2)), with: .color(.white.opacity(0.5)))
    }

    // MARK: M 잔상

    private mutating func drawEcho(colors: StyleCardBackdropColors, poseImage: Image) {
        fillCard(top: colors.base, bottom: colors.deep)
        glow(at: CGPoint(x: 140, y: 120), radius: 120, color: colors.glow, opacity: colors.glowOpacity)
        for _ in 0..<12 {
            let y = 30 + rng.next() * 170, width = 40 + rng.next() * 90, x = rng.next() * 70 - 20
            let height = 1.5 + rng.next() * 2, opacity = 0.15 + rng.next() * 0.3
            context.fill(Path(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: 1), with: .color(colors.light.opacity(opacity)))
        }
        context.fill(Path(CGRect(x: 24, y: 206, width: 214, height: 1.5)), with: .color(colors.light.opacity(0.35)))
        for (index, color, opacity) in [(3, colors.mid, 0.32), (2, colors.mid, 0.48), (1, colors.light, 0.62)] {
            tinted(poseImage, in: CGRect(x: 23 - CGFloat(index) * 15, y: CGFloat(index) * 3, width: 216, height: 216), color: color, opacity: opacity)
        }
    }

    // MARK: 도구

    /// 캐릭터 그림을 한 색으로 칠해 그린다(잔상)
    mutating func tinted(_ image: Image, in rect: CGRect, color: Color, opacity: Double) {
        var faded = context
        faded.opacity = opacity
        faded.drawLayer { layer in
            layer.draw(image, in: rect)
            layer.blendMode = .sourceIn
            layer.fill(Path(rect), with: .color(color))
        }
    }

    /// 점수판 전광판 글자 — 점으로 찍은 흰 글자와 번짐
    mutating func ledText(_ string: String, size: CGFloat, center: CGPoint, glowOpacity: Double) {
        let font = Font.cookieRun.custom(weight: .black, size: size)
        var blurred = context
        blurred.opacity = glowOpacity
        blurred.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.draw(Text(string).font(font).foregroundStyle(Color.white), at: center)
        }
        // 점 격자를 글자 모양으로 오린다(blendMode는 점 안쪽에만 먹어 글자가 통째로 남는다)
        var dotted = context
        dotted.clipToLayer { layer in
            layer.draw(Text(string).font(font).foregroundStyle(Color.white), at: center)
        }
        dotted.fill(Self.dotGrid(height: 394, radius: 2), with: .color(.white))
    }

    static func dotGrid(height: CGFloat, radius: CGFloat) -> Path {
        var path = Path()
        for y in stride(from: CGFloat(3), to: height, by: 6) {
            for x in stride(from: CGFloat(3), to: 262, by: 6) {
                path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            }
        }
        return path
    }

    /// 점수판 위 시계 · 어드밴티지 · 띠 조각
    private mutating func scoreboardChrome(colors: StyleCardBackdropColors, showsPenalty: Bool) {
        text("04:32", font: .cookieRun.custom(weight: .black, size: 15), color: .white.opacity(0.75), at: CGPoint(x: 28, y: 29), anchor: .leading)
        if showsPenalty {
            let font = Font.pretendard.custom(weight: .semiBold, size: 9)
            text("ADV 0", font: font, color: .white.opacity(0.6), at: CGPoint(x: 176, y: 21), anchor: .leading)
            text("PEN 0", font: font, color: .white.opacity(0.6), at: CGPoint(x: 176, y: 34), anchor: .leading)
        }
        context.fill(Path(roundedRect: CGRect(x: 216, y: 18, width: 20, height: 22), cornerRadius: 3), with: .color(colors.beltLine))
        context.fill(Path(CGRect(x: 228, y: 18, width: 8, height: 22)), with: .color(colors.rank))
    }
}
