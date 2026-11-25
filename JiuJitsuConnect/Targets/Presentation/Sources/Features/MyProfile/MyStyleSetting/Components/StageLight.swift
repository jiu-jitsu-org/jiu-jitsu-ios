//
//  StageLight.swift
//  Presentation
//

import SwiftUI

/// 어두운 무대에서 고른 카드를 비추는 조명
///
/// 카드와 같은 크기로 두면 카드 밖까지 그린다. 빛은 화면 위 밖에서 내려와 윗변이 보이지 않고,
/// 카드 뒤로 은은하게 번지며, 카드가 선 바닥에 고인다. 바탕에 더해지는 빛이라 어두운 바탕에서만 쓴다.
struct StageLight: View {
    let cardSize: CGSize
    let cornerRadius: CGFloat

    private enum Metrics {
        /// 빛줄기가 카드 위로 올라가는 길이 — 화면 위 밖까지 닿게 넉넉히
        static let beamRise: CGFloat = 320
        /// 빛줄기가 카드 아래로 내려가는 길이
        static let beamDrop: CGFloat = 40
        static let beamTopWidth: CGFloat = 90
        static let beamBottomWidth: CGFloat = 430
    }

    var body: some View {
        ZStack {
            beam
            halo
            floorPool
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var beam: some View {
        let height = Metrics.beamRise + cardSize.height + Metrics.beamDrop
        return Cone(topRatio: Metrics.beamTopWidth / Metrics.beamBottomWidth)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.1), location: 0),
                        .init(color: .white.opacity(0.3), location: 0.35),
                        .init(color: .white.opacity(0.14), location: 0.85),
                        .init(color: .white.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: Metrics.beamBottomWidth, height: height)
            .blur(radius: 26)
            // 카드 가운데를 기준으로 위로 올린다
            .offset(y: (Metrics.beamDrop - Metrics.beamRise) / 2)
    }

    /// 카드 둘레로 번지는 빛
    private var halo: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.2))
            .frame(width: cardSize.width * 1.04, height: cardSize.height * 1.02)
            .blur(radius: 40)
    }

    /// 카드가 선 바닥에 고인 빛
    private var floorPool: some View {
        Ellipse()
            .fill(
                EllipticalGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0)],
                    center: .center
                )
            )
            .frame(width: cardSize.width * 1.6, height: 72)
            .blur(radius: 6)
            .offset(y: cardSize.height / 2 + 14)
    }
}

/// 위가 좁고 아래가 넓은 빛줄기 모양
private struct Cone: Shape {
    let topRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = rect.width * (1 - topRatio) / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("StageLight") {
    ZStack {
        StageLight(cardSize: CGSize(width: 262, height: 394), cornerRadius: StyleCardMetrics.cornerRadius)
        RoundedRectangle(cornerRadius: 40)
            .fill(Color.orange)
            .frame(width: 262, height: 394)
    }
    .padding(200)
    .background(Color.black)
}
