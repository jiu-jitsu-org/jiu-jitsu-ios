//
//  FlipCard.swift
//  Presentation
//

import SwiftUI

/// 세로축으로 도는 앞뒤 두 면 카드
///
/// 각도를 애니메이션 값으로 받아, 도는 도중 정확히 옆면(90도)을 지날 때 보이는 면을 바꾼다.
/// (각도 상태만 보고 바꾸면 돌기 시작하는 순간 두 면이 겹쳐 비친다)
struct FlipCard<Front: View, Back: View>: View, Animatable {
    /// 0 = 앞면, 180 = 뒷면. 한 바퀴를 넘겨도 된다.
    var angle: Double
    var perspective: Double = 0.4
    @ViewBuilder let front: Front
    @ViewBuilder let back: Back

    nonisolated var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var showsBack: Bool {
        let normalized = angle.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return positive > 90 && positive < 270
    }

    var body: some View {
        ZStack {
            // 뒷면은 처음부터 180도 뒤집어 대기
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsBack ? 1 : 0)
                .accessibilityHidden(!showsBack)

            front
                .opacity(showsBack ? 0 : 1)
                .accessibilityHidden(showsBack)
        }
        .animation(nil, value: showsBack)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: perspective)
    }
}
