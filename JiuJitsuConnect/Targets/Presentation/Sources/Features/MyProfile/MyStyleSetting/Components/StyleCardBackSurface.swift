//
//  StyleCardBackSurface.swift
//  Presentation
//

import SwiftUI
import DesignSystem

/// 최애 카드 뒷면 바탕 — 회색 면에 로고의 S를 크게 깔고 옅은 테두리를 두른다.
///
/// MY의 작은 카드와 설정 화면의 큰 카드가 크기만 다르게 같이 쓴다.
struct StyleCardBackSurface: View {
    let cornerRadius: CGFloat
    var borderWidth: CGFloat = 1

    // 시안(827×972 카드) 기준 값
    private enum Design {
        static let cardWidth: CGFloat = 827
        static let cardHeight: CGFloat = 972
        // 시안 그대로(10.49)는 S가 카드를 거의 다 덮어 시끄러워, 62%로 줄이고 더 옅게 깐다(#495)
        static let letterScale: CGFloat = 10.49 * 0.62
        static let letterAngle: Double = -30.3
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        GeometryReader { proxy in
            // 카드가 시안보다 길쭉해도 무늬가 위아래를 채우게 큰 쪽 배율을 쓴다.
            let scale = max(proxy.size.width / Design.cardWidth, proxy.size.height / Design.cardHeight)
                * Design.letterScale

            ZStack {
                Color(hex: "#656565")

                LogoLetterShape()
                    .fill(Color(hex: "#6F6F6F"))
                    .frame(
                        width: LogoLetterShape.size.width * scale,
                        height: LogoLetterShape.size.height * scale
                    )
                    .rotationEffect(.degrees(Design.letterAngle))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color(hex: "#B2B2B2"), lineWidth: borderWidth))
    }
}

/// 앱 로고(Splash/logo)의 S 한 글자
private struct LogoLetterShape: Shape {
    static let size = CGSize(width: 85.94, height: 97.18)

    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / Self.size.width
        let scaleY = rect.height / Self.size.height
        func point(_ pointX: CGFloat, _ pointY: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + pointX * scaleX, y: rect.minY + pointY * scaleY)
        }

        var path = Path()
        path.move(to: point(40.2, 68.85))
        path.addCurve(to: point(42.58, 66.47), control1: point(41.79, 68.57), control2: point(42.58, 67.77))
        path.addCurve(to: point(41.28, 61.99), control1: point(42.58, 65.12), control2: point(42.15, 63.63))
        path.addCurve(to: point(37.6, 57.22), control1: point(40.47, 60.3), control2: point(39.24, 58.72))
        path.addCurve(to: point(20.19, 51.44), control1: point(33.31, 53.37), control2: point(27.51, 51.44))
        path.addCurve(to: point(10.07, 53.25), control1: point(16.58, 51.44), control2: point(13.2, 52.04))
        path.addCurve(to: point(2.13, 45.23), control1: point(6.75, 51.56), control2: point(4.1, 48.89))
        path.addCurve(to: point(-0.84, 33.38), control1: point(0.15, 41.57), control2: point(-0.84, 37.62))
        path.addCurve(to: point(13.03, 7.73), control1: point(-0.84, 22.3), control2: point(3.79, 13.75))
        path.addCurve(to: point(42.44, 0), control1: point(20.98, 2.58), control2: point(30.78, 0))
        path.addCurve(to: point(64.33, 2.82), control1: point(51.11, 0), control2: point(58.41, 0.94))
        path.addCurve(to: point(78.85, 9.9), control1: point(70.25, 4.65), control2: point(75.09, 7.01))
        path.addCurve(to: point(80.51, 19.8), control1: point(79.96, 13.08), control2: point(80.51, 16.38))
        path.addCurve(to: point(79.14, 29.12), control1: point(80.51, 23.22), control2: point(80.06, 26.32))
        path.addCurve(to: point(75.17, 35.84), control1: point(78.23, 31.91), control2: point(76.9, 34.15))
        path.addCurve(to: point(66.28, 32.15), control1: point(73.53, 34.63), control2: point(70.57, 33.41))
        path.addCurve(to: point(54.58, 30.27), control1: point(61.99, 30.9), control2: point(58.09, 30.27))
        path.addCurve(to: point(47.5, 30.92), control1: point(51.06, 30.27), control2: point(48.7, 30.49))
        path.addCurve(to: point(45.76, 32.95), control1: point(46.34, 31.36), control2: point(45.76, 32.03))
        path.addCurve(to: point(45.98, 34.18), control1: point(45.76, 33.38), control2: point(45.84, 33.79))
        path.addCurve(to: point(52.48, 33.53), control1: point(47.66, 33.74), control2: point(49.83, 33.53))
        path.addCurve(to: point(75.46, 40.17), control1: point(61.87, 33.53), control2: point(69.53, 35.74))
        path.addCurve(to: point(85.93, 64.01), control1: point(82.44, 45.47), control2: point(85.93, 53.42))
        path.addCurve(to: point(74.59, 87.28), control1: point(85.93, 73.36), control2: point(82.15, 81.11))
        path.addCurve(to: point(41.57, 97.17), control1: point(66.4, 93.88), control2: point(55.4, 97.17))
        path.addCurve(to: point(21.78, 95.44), control1: point(33.96, 97.17), control2: point(27.36, 96.6))
        path.addCurve(to: point(5.45, 89.52), control1: point(16.19, 94.33), control2: point(10.75, 92.36))
        path.addCurve(to: point(0.03, 73.55), control1: point(1.84, 84.27), control2: point(0.03, 78.94))
        path.addCurve(to: point(5.59, 60.04), control1: point(0.03, 68.11), control2: point(1.88, 63.6))
        path.addCurve(to: point(19.25, 54.69), control1: point(9.3, 56.48), control2: point(13.85, 54.69))
        path.addCurve(to: point(32.54, 58.02), control1: point(24.69, 54.69), control2: point(29.12, 55.8))
        path.addCurve(to: point(40.2, 68.85), control1: point(36.01, 60.23), control2: point(38.56, 63.85))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("StyleCardBackSurface") {
    HStack {
        StyleCardBackSurface(cornerRadius: 24).frame(width: 110, height: 130)
        StyleCardBackSurface(cornerRadius: StyleCardMetrics.cornerRadius, borderWidth: 2).frame(width: 262, height: 394)
    }
}
