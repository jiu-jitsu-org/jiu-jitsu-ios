//
//  BackdropPainter+Impact.swift
//  Presentation
//
//  1 충격 시안(#495) — 기술의 힘이 터지는 장면. 기술마다 충격 지점 · 방향 · 파편 모양이 다르다.
//

import SwiftUI

extension BackdropPainter {
    // swiftlint:disable:next cyclomatic_complexity
    mutating func impactScene(_ impact: StyleImpact, colors: StyleCardBackdropColors) {
        let shards = [colors.glow, colors.light, colors.strap, colors.accent]
        let layers = [colors.mid, colors.light, colors.glow]
        switch impact.kind {
        case .slam: slam(impact.point, colors: colors, shards: shards, layers: layers)
        case .press: press(colors: colors, shards: shards, layers: layers)
        case .block: block(impact.point, colors: colors, shards: shards, layers: layers)
        case .breakOut: breakOut(impact.point, colors: colors, shards: shards)
        case .snap: snap(impact.point, colors: colors, shards: shards, layers: layers)
        case .squeeze: squeeze(impact.point, colors: colors)
        case .twist: twist(impact.point, colors: colors, shards: shards, layers: layers)
        case .through: through(impact.point, colors: colors, layers: layers)
        case .spin: spin(impact.point, colors: colors, shards: shards, layers: layers)
        }
    }

    private var deg: CGFloat { BackdropShape.degree }

    /// 테이크다운 — 바닥에 꽂혀 납작한 충격파, 파편이 위로 튀고 바닥에 금
    private mutating func slam(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        let light = colors.light
        arcs(at, radius: 46, scaleY: 0.16, from: 0, to: .pi * 2, segments: 5, color: light, width: 2.4, opacity: 0.85)
        arcs(at, radius: 88, scaleY: 0.15, from: 0, to: .pi * 2, segments: 6, color: light, width: 2, opacity: 0.55)
        arcs(at, radius: 132, scaleY: 0.14, from: 0, to: .pi * 2, segments: 7, color: light, width: 1.6, opacity: 0.35)
        blast(at, count: 12, radius: 132, SpikyOptions(dir: -.pi / 2, stretch: 0.5, startAngle: .pi, endAngle: .pi * 2), colors: layers)
        for _ in 0..<18 {
            let angle = (-170 + rng.next() * 160) * deg, distance = 60 + rng.next() * 120
            let length = 10 + rng.next() * 18, width = 5 + rng.next() * 6
            let color = rng.pick(shards), trail = 14 + rng.next() * 24
            shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
        }
        crack(from: CGPoint(x: at.x - 20, y: at.y + 4), angle: .pi, length: 110, color: light, width: 2)
        crack(from: CGPoint(x: at.x + 20, y: at.y + 4), angle: 0, length: 80, color: light, width: 2)
    }

    /// 탑 — 위에서 내리누르는 폭발, 파편이 비처럼 떨어지고 바닥에 금
    private mutating func press(colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        let light = colors.light
        blast(CGPoint(x: 131, y: -8), count: 13, radius: 150, SpikyOptions(dir: .pi / 2, stretch: 0.35, startAngle: 0, endAngle: .pi), colors: layers)
        for _ in 0..<20 {
            let x = 8 + rng.next() * 246, y = 30 + rng.next() * 160, angle = (90 + (rng.next() - 0.5) * 22) * deg
            let length = 10 + rng.next() * 18, width = 4 + rng.next() * 5
            let color = rng.pick(shards), trail = 18 + rng.next() * 30
            shard(CGPoint(x: x, y: y), length: length, width: width, angle: angle, color: color, trail: trail, trailColor: light, opacity: 0.9)
        }
        let ground = CGPoint(x: 131, y: 204)
        arcs(ground, radius: 54, scaleY: 0.15, from: 0, to: .pi * 2, segments: 5, color: light, width: 2.2, opacity: 0.7)
        arcs(ground, radius: 100, scaleY: 0.14, from: 0, to: .pi * 2, segments: 6, color: light, width: 1.6, opacity: 0.4)
        crack(from: CGPoint(x: 110, y: 207), angle: .pi, length: 90, color: light, width: 1.8)
        crack(from: CGPoint(x: 152, y: 207), angle: 0, length: 90, color: light, width: 1.8)
    }

    /// 가드 — 밀고 온 힘을 세로로 막아 서고, 파편이 왼쪽으로 튕겨 나감
    private mutating func block(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        let light = colors.light
        arcs(at, radius: 52, scaleY: 1, from: 125 * deg, to: 235 * deg, segments: 2, color: light, width: 3, opacity: 0.85)
        arcs(at, radius: 84, scaleY: 1, from: 130 * deg, to: 230 * deg, segments: 3, color: light, width: 2.2, opacity: 0.55)
        arcs(at, radius: 116, scaleY: 1, from: 135 * deg, to: 225 * deg, segments: 3, color: light, width: 1.6, opacity: 0.35)
        blast(at, count: 12, radius: 64, SpikyOptions(jitter: 0.5, vertical: 1.5), colors: layers)
        for _ in 0..<16 {
            let angle = (140 + rng.next() * 80) * deg, distance = 40 + rng.next() * 90
            let length = 9 + rng.next() * 16, width = 4 + rng.next() * 6
            let color = rng.pick(shards), trail = 12 + rng.next() * 22
            shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
        }
        for _ in 0..<5 {
            let angle = (-40 + rng.next() * 80) * deg, distance = 30 + rng.next() * 30
            chip(BackdropShape.point(at, distance, angle), length: 7, width: 3, angle: angle, color: colors.glow)
        }
    }

    /// 이스케이프 — 둘러싼 껍질이 조각나며 밖으로 밀려남
    private mutating func breakOut(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color]) {
        blast(at, count: 14, radius: 84, SpikyOptions(jitter: 0.6), colors: [colors.light, colors.glow, colors.glow])
        let segments = 9
        for index in 0..<segments {
            let start = CGFloat(index) / CGFloat(segments) * .pi * 2 + rng.next() * 0.12
            let end = CGFloat(index + 1) / CGFloat(segments) * .pi * 2 - 0.1 - rng.next() * 0.1
            let middle = (start + end) / 2, push = 10 + rng.next() * 18
            let innerRadius: CGFloat = 92, outerRadius: CGFloat = 112
            var piece = (0...6).map { step in
                BackdropShape.point(at, outerRadius, start + (end - start) * CGFloat(step) / 6, scaleY: 0.9)
            }
            piece.append(BackdropShape.point(at, innerRadius, end - 0.05, scaleY: 0.9))
            piece.append(BackdropShape.point(at, innerRadius + 6, middle, scaleY: 0.9))
            piece.append(BackdropShape.point(at, innerRadius, start + 0.05, scaleY: 0.9))
            let turn = (rng.next() - 0.5) * 16
            let pivot = CGPoint(x: at.x + 102 * cos(middle), y: at.y + 92 * sin(middle))
            var moved = context
            moved.translateBy(x: cos(middle) * push, y: sin(middle) * push)
            moved.translateBy(x: pivot.x, y: pivot.y)
            moved.rotate(by: .degrees(turn))
            moved.translateBy(x: -pivot.x, y: -pivot.y)
            let path = BackdropShape.polygon(piece)
            moved.fill(path, with: .color(colors.strap))
            moved.stroke(path, with: .color(colors.light), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            let flyAngle = middle + 0.25
            let flyPoint = CGPoint(x: at.x + 128 * cos(flyAngle), y: at.y + 116 * sin(flyAngle))
            let length = 9 + rng.next() * 8, width = 4 + rng.next() * 3, color = rng.pick(shards)
            shard(flyPoint, length: length, width: width, angle: flyAngle, color: color, trail: 14)
        }
        arcs(at, radius: 140, scaleY: 0.9, from: 0, to: .pi * 2, segments: 8, color: colors.light, width: 1.6, opacity: 0.35)
    }

    /// 팔 관절기 — 한 점에서 금이 사방으로 가고 작은 폭발이 튐
    private mutating func snap(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        for (index, degrees) in [-150, -62, 8, 62, 158, 112].enumerated() {
            let length = 110 + rng.next() * 90
            crack(from: at, angle: CGFloat(degrees) * deg, length: length, color: index % 2 == 1 ? colors.light : colors.glow, width: 2.2)
        }
        blast(at, count: 13, radius: 74, SpikyOptions(jitter: 0.75), colors: layers)
        fillSpiky(CGPoint(x: at.x - 96, y: at.y + 74), count: 7, inner: 6, outer: 18, color: colors.glow, opacity: 0.9)
        fillSpiky(CGPoint(x: at.x + 70, y: at.y - 70), count: 6, inner: 5, outer: 14, color: colors.light)
        for _ in 0..<12 {
            let angle = rng.next() * .pi * 2, distance = 50 + rng.next() * 80
            let length = 8 + rng.next() * 14, width = 4 + rng.next() * 4
            let color = rng.pick(shards), trail = 10 + rng.next() * 16
            shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail)
        }
    }

    /// 조르기 — 사방의 파편이 안쪽을 향해 조여들고 고리가 좁혀 옴
    private mutating func squeeze(_ at: CGPoint, colors: StyleCardBackdropColors) {
        arcs(at, radius: 66, scaleY: 1, from: 0, to: .pi * 2, segments: 4, color: colors.light, width: 2.6, opacity: 0.8)
        arcs(at, radius: 92, scaleY: 1, from: 0.4, to: .pi * 2 + 0.4, segments: 5, color: colors.light, width: 2, opacity: 0.5)
        blast(at, count: 16, radius: 50, SpikyOptions(jitter: 0.3), colors: [colors.light, colors.glow, colors.glow])
        for index in 0..<24 {
            let angle = CGFloat(index) / 24 * .pi * 2 + (rng.next() - 0.5) * 0.2, distance = 108 + rng.next() * 50
            let length = 16 + rng.next() * 20, width = 6 + rng.next() * 6
            let color = rng.pick([colors.glow, colors.light, colors.strap]), trail = 16 + rng.next() * 20
            shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle + .pi, color: color, trail: trail, trailColor: colors.light)
        }
    }

    /// 하체 관절기 — 파편이 소용돌이를 따라 감겨 들어감
    private mutating func twist(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        let spiral: (CGFloat) -> CGPoint = { progress in
            let angle = progress * 3.3 * .pi + 0.4, radius = 26 + progress * 140
            return BackdropShape.point(at, radius, angle, scaleY: 0.82)
        }
        stroke((0...60).map { spiral(CGFloat($0) / 60) }, colors.light, width: 2, opacity: 0.35)
        blast(at, count: 11, radius: 62, SpikyOptions(jitter: 0.6), colors: layers)
        for index in 0..<24 {
            let progress = 0.12 + CGFloat(index) / 24 * 0.88, angle = progress * 3.3 * .pi + 0.4
            let length = 8 + progress * 24, width = 4 + progress * 7, color = rng.pick(shards)
            shard(spiral(progress), length: length, width: width, angle: angle + .pi / 2, color: color, trail: 10 + progress * 22)
        }
    }

    /// 가드패스 — 왼쪽 벽이 뚫리고 파편이 오른쪽으로 길게 날아감
    private mutating func through(_ at: CGPoint, colors: StyleCardBackdropColors, layers: [Color]) {
        let wall: [CGPoint] = [
            (-4, -4), (44, -4), (38, 30), (50, 52), (40, 74), (62, 92), (52, 112),
            (64, 134), (44, 152), (50, 180), (36, 214), (-4, 214)
        ].map { CGPoint(x: $0.0, y: $0.1) }
        fill(wall, colors.strap)
        stroke(Array(wall.dropFirst().dropLast()), colors.light, width: 1.4, opacity: 0.7)
        arcs(at, radius: 44, scaleY: 1, from: -60 * deg, to: 60 * deg, segments: 2, color: colors.light, width: 2.8, opacity: 0.85)
        arcs(at, radius: 76, scaleY: 1, from: -55 * deg, to: 55 * deg, segments: 3, color: colors.light, width: 2.2, opacity: 0.55)
        arcs(at, radius: 110, scaleY: 1, from: -50 * deg, to: 50 * deg, segments: 3, color: colors.light, width: 1.6, opacity: 0.35)
        blast(at, count: 11, radius: 64, SpikyOptions(dir: 0, stretch: 1.3), colors: layers)
        for _ in 0..<20 {
            let angle = (-32 + rng.next() * 64) * deg, distance = 40 + rng.next() * 170
            let length = 10 + rng.next() * 18, width = 5 + rng.next() * 7
            let color = rng.pick([colors.strap, colors.light, colors.glow]), trail = 24 + rng.next() * 36
            shard(BackdropShape.point(at, distance, angle), length: length, width: width, angle: angle, color: color, trail: trail, trailColor: colors.light)
        }
    }

    /// 스윕 — 둥근 궤적을 따라 파편이 돌고, 뒤집히는 자리에서 터짐
    private mutating func spin(_ at: CGPoint, colors: StyleCardBackdropColors, shards: [Color], layers: [Color]) {
        let orbits: [(radius: CGFloat, start: CGFloat, end: CGFloat)] = [(72, 200, 340), (98, 30, 170), (124, 220, 330)]
        for (index, orbit) in orbits.enumerated() {
            let points = (0...24).map { step in
                BackdropShape.point(at, orbit.radius, (orbit.start + (orbit.end - orbit.start) * CGFloat(step) / 24) * deg, scaleY: 0.86)
            }
            stroke(points, colors.light, width: 2.6 - CGFloat(index) * 0.5, opacity: 0.8 - Double(index) * 0.2)
            if let tip = points.last {
                chip(tip, length: 18, width: 8, angle: orbit.end * deg + .pi / 2, color: colors.glow)
            }
        }
        blast(CGPoint(x: 196, y: 58), count: 11, radius: 56, SpikyOptions(jitter: 0.6), colors: layers)
        blast(CGPoint(x: 60, y: 174), count: 9, radius: 34, colors: [colors.light, colors.glow, colors.glow])
        for _ in 0..<16 {
            let angle = rng.next() * .pi * 2, radius = 92 + rng.next() * 40
            let length = 8 + rng.next() * 14, width = 4 + rng.next() * 4
            let color = rng.pick(shards), trail = 12 + rng.next() * 14
            shard(BackdropShape.point(at, radius, angle, scaleY: 0.86), length: length, width: width, angle: angle + .pi / 2, color: color, trail: trail)
        }
    }
}
