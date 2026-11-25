//
//  BackdropPainter.swift
//  Presentation
//
//  최애 기술 카드 바탕(#495)을 그리는 도형 도구 — 뾰족한 폭발 · 파편 · 끊어진 충격파 · 금.
//  시안 페이지의 계산을 그대로 옮겨, 같은 씨앗이면 같은 모양이 나온다.
//

import SwiftUI

// MARK: - 씨앗 난수

/// 기술마다 파편 배치를 고정하는 난수(mulberry32). 매번 그려도 같은 모양이 나온다.
struct SeededRandom {
    private var state: UInt32

    init(seed: Int) {
        state = UInt32(truncatingIfNeeded: seed)
    }

    mutating func next() -> CGFloat {
        state = state &+ 0x6D2B79F5
        var value = (state ^ (state >> 15)) &* (1 | state)
        value = (value &+ ((value ^ (value >> 7)) &* (61 | value))) ^ value
        return CGFloat(value ^ (value >> 14)) / 4_294_967_296
    }

    mutating func pick<T>(_ items: [T]) -> T {
        items[min(items.count - 1, Int(next() * CGFloat(items.count)))]
    }
}

// MARK: - 도형

struct SpikyOptions {
    var dir: CGFloat = 0
    var stretch: CGFloat = 0
    var jitter: CGFloat = 0.55
    var startAngle: CGFloat = 0
    var endAngle: CGFloat = .pi * 2
    var scaleY: CGFloat = 1
    var vertical: CGFloat = 0
}

enum BackdropShape {
    static let degree = CGFloat.pi / 180

    /// 뾰족한 폭발. 긴 가시 · 짧은 가시를 번갈아 두툼하게, `dir` 쪽으로 늘어난다.
    /// 일부 각도만 그리면 중심으로 닫는다.
    static func spiky(
        _ center: CGPoint, count: Int, inner: CGFloat, outer: CGFloat,
        rng: inout SeededRandom, _ options: SpikyOptions = SpikyOptions()
    ) -> [CGPoint] {
        let span = options.endAngle - options.startAngle
        let full = span >= .pi * 2 - 1e-6
        let total = count * 2
        var points: [CGPoint] = []
        for index in 0...(full ? total - 1 : total) {
            let isOuter = index % 2 == 0
            let wobble = isOuter ? (rng.next() - 0.5) * span / CGFloat(total) * 0.9 : 0
            let angle = options.startAngle + span * CGFloat(index) / CGFloat(total) + wobble
            let boost = 1 + options.stretch * pow(max(0, cos(angle - options.dir)), 2) + options.vertical * abs(sin(angle))
            let rhythm: CGFloat = isOuter && (index / 2) % 2 == 1 ? 0.58 + rng.next() * 0.18 : 1
            let radius: CGFloat
            if isOuter {
                let length = outer * (1 - options.jitter / 2 + rng.next() * options.jitter) * boost * rhythm
                radius = max(inner * 1.25, length)
            } else {
                radius = inner * (0.8 + rng.next() * 0.4)
            }
            points.append(CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle) * options.scaleY))
        }
        if !full { points.append(center) }
        return points
    }

    /// 날아가는 파편(비대칭 마름모)
    static func shard(_ center: CGPoint, length: CGFloat, width: CGFloat, angle: CGFloat, rng: inout SeededRandom) -> [CGPoint] {
        let ux = cos(angle), uy = sin(angle), vx = -uy, vy = ux
        let bias = 0.3 + rng.next() * 0.5
        return [
            CGPoint(x: center.x + ux * length * 0.62, y: center.y + uy * length * 0.62),
            CGPoint(x: center.x + ux * length * 0.02 + vx * width * bias, y: center.y + uy * length * 0.02 + vy * width * bias),
            CGPoint(x: center.x - ux * length * 0.38, y: center.y - uy * length * 0.38),
            CGPoint(
                x: center.x - ux * length * 0.1 - vx * width * (1 - bias),
                y: center.y - uy * length * 0.1 - vy * width * (1 - bias)
            )
        ]
    }

    /// 파편 뒤 꼬리(가는 삼각형)
    static func trail(_ center: CGPoint, length: CGFloat, angle: CGFloat, width: CGFloat) -> [CGPoint] {
        let ux = cos(angle), uy = sin(angle), vx = -uy, vy = ux
        return [
            CGPoint(x: center.x + vx * width, y: center.y + vy * width),
            CGPoint(x: center.x - vx * width, y: center.y - vy * width),
            CGPoint(x: center.x - ux * length, y: center.y - uy * length)
        ]
    }

    static func polygon(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }

    static func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        return path
    }

    static func point(_ center: CGPoint, _ radius: CGFloat, _ angle: CGFloat, scaleY: CGFloat = 1) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle) * scaleY)
    }
}

// MARK: - 그리기

/// 카드 좌표(262×394)에서 바탕 도형을 그리는 붓
struct BackdropPainter {
    static let cardSize = CGSize(width: 262, height: 394)
    static let cardRect = CGRect(origin: .zero, size: cardSize)

    var context: GraphicsContext
    var rng: SeededRandom

    mutating func fill(_ points: [CGPoint], _ color: Color, opacity: Double = 1) {
        context.fill(BackdropShape.polygon(points), with: .color(color.opacity(opacity)))
    }

    mutating func stroke(_ points: [CGPoint], _ color: Color, width: CGFloat, opacity: Double = 1, closed: Bool = false, dash: [CGFloat] = []) {
        let path = closed ? BackdropShape.polygon(points) : BackdropShape.polyline(points)
        context.stroke(
            path, with: .color(color.opacity(opacity)),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash)
        )
    }

    mutating func fillCard(_ color: Color) {
        context.fill(Path(Self.cardRect), with: .color(color))
    }

    /// 위는 `top`, 아래는 `bottom`인 세로 그라데이션 바탕
    mutating func fillCard(top: Color, bottom: Color, from: CGFloat = 0, to: CGFloat = 394) {
        context.fill(
            Path(Self.cardRect),
            with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: CGPoint(x: 0, y: from), endPoint: CGPoint(x: 0, y: to))
        )
    }

    /// 캐릭터 바로 뒤를 밝히는 빛
    mutating func glow(at center: CGPoint, radius: CGFloat, color: Color, opacity: Double) {
        let gradient = Gradient(stops: [
            .init(color: color.opacity(opacity), location: 0),
            .init(color: color.opacity(opacity * 0.35), location: 0.55),
            .init(color: color.opacity(0), location: 1)
        ])
        context.fill(Path(Self.cardRect), with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius))
    }

    mutating func spiky(
        _ center: CGPoint, count: Int, inner: CGFloat, outer: CGFloat,
        _ options: SpikyOptions = SpikyOptions()
    ) -> [CGPoint] {
        BackdropShape.spiky(center, count: count, inner: inner, outer: outer, rng: &rng, options)
    }

    mutating func fillSpiky(
        _ center: CGPoint, count: Int, inner: CGFloat, outer: CGFloat,
        _ options: SpikyOptions = SpikyOptions(), color: Color, opacity: Double = 1
    ) {
        let points = spiky(center, count: count, inner: inner, outer: outer, options)
        fill(points, color, opacity: opacity)
    }

    /// 세 겹 폭발(바깥 → 가운데 → 심)
    mutating func blast(_ center: CGPoint, count: Int, radius: CGFloat, _ options: SpikyOptions = SpikyOptions(), colors: [Color]) {
        let spikes = max(6, count - 3)
        fillSpiky(center, count: spikes, inner: radius * 0.48, outer: radius * 1.08, options, color: colors[0])
        fillSpiky(center, count: spikes - 1, inner: radius * 0.38, outer: radius * 0.74, options, color: colors[1])
        var core = options
        core.jitter = 0.35
        fillSpiky(center, count: spikes - 1, inner: radius * 0.26, outer: radius * 0.46, core, color: colors[2])
    }

    /// 파편과 그 뒤 꼬리
    mutating func shard(
        _ center: CGPoint, length: CGFloat, width: CGFloat, angle: CGFloat, color: Color,
        trail: CGFloat = 0, trailColor: Color? = nil, opacity: Double = 1
    ) {
        let length = length * 1.4, width = width * 1.5
        if trail > 0 {
            let tail = CGPoint(x: center.x - cos(angle) * length * 0.3, y: center.y - sin(angle) * length * 0.3)
            fill(BackdropShape.trail(tail, length: trail, angle: angle, width: width * 0.22), trailColor ?? color, opacity: opacity * 0.55)
        }
        fill(BackdropShape.shard(center, length: length, width: width, angle: angle, rng: &rng), color, opacity: opacity)
    }

    /// 작은 파편(꼬리 없이, 크기 그대로)
    mutating func chip(_ center: CGPoint, length: CGFloat, width: CGFloat, angle: CGFloat, color: Color) {
        fill(BackdropShape.shard(center, length: length, width: width, angle: angle, rng: &rng), color)
    }

    /// 끊어진 충격파 고리
    mutating func arcs(
        _ center: CGPoint, radius: CGFloat, scaleY: CGFloat, from start: CGFloat, to end: CGFloat,
        segments: Int, color: Color, width: CGFloat, opacity: Double
    ) {
        let span = (end - start) / CGFloat(segments)
        for index in 0..<segments {
            let segStart = start + span * CGFloat(index) + span * rng.next() * 0.25
            let segEnd = start + span * CGFloat(index + 1) - span * (0.15 + rng.next() * 0.3)
            let points = (0...10).map { step -> CGPoint in
                let angle = segStart + (segEnd - segStart) * CGFloat(step) / 10
                return BackdropShape.point(center, radius, angle, scaleY: scaleY)
            }
            stroke(points, color, width: width, opacity: opacity)
        }
    }

    /// 갈라지는 금(중간에 가지 하나)
    mutating func crack(from origin: CGPoint, angle: CGFloat, length: CGFloat, color: Color, width: CGFloat) {
        var points = [origin]
        var current = origin
        var travelled: CGFloat = 0
        var branch: [CGPoint]?
        while travelled < length {
            let step = 9 + rng.next() * 9
            let heading = angle + (rng.next() - 0.5) * 0.9
            current = CGPoint(x: current.x + cos(heading) * step, y: current.y + sin(heading) * step)
            travelled += step
            points.append(current)
            if branch == nil, travelled > length * 0.45 {
                branch = [current, CGPoint(x: current.x + cos(angle + 0.7) * length * 0.3, y: current.y + sin(angle + 0.7) * length * 0.3)]
            }
        }
        stroke(points, color, width: width)
        if let branch { stroke(branch, color, width: width * 0.6) }
    }

    /// 글자. `point`는 글자 가운데.
    mutating func text(_ string: String, font: Font, color: Color, at point: CGPoint, anchor: UnitPoint = .center) {
        context.draw(Text(string).font(font).foregroundStyle(color), at: point, anchor: anchor)
    }
}

extension GraphicsContext {
    /// 카드 아래 글자 자리로 넘어가지 않게, 그린 것을 위쪽(197~222)에서 흐리게 끝낸다
    func fadingAtTextArea(_ draw: (inout GraphicsContext) -> Void) {
        drawLayer { layer in
            draw(&layer)
            layer.blendMode = .destinationIn
            layer.fill(
                Path(BackdropPainter.cardRect),
                with: .linearGradient(
                    Gradient(colors: [.white, .white.opacity(0)]),
                    startPoint: CGPoint(x: 0, y: 197), endPoint: CGPoint(x: 0, y: 222)
                )
            )
        }
    }
}
