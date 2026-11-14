//
//  WebLoadingOverlay.swift
//  Presentation
//
//  웹뷰를 덮는 로딩 덮개(홈 피드·대회 탭 공용, #261). 쌓이는 웹 화면은 덮개 없이 웹 스켈레톤을 보이고(#299),
//  스켈레톤이 오기 전(첫 응답 전)에만 덮지 않는 스피너(WebFirstResponseSpinner)를 얹는다.
//

import SwiftUI
import DesignSystem

/// 웹 화면이 그려지기 전까지 웹뷰를 덮는 로딩 덮개.
///
/// - 덮는 동안은 아래 웹을 가리고 탭을 막는다.
/// - 걷힐 때만 `fadeDuration`에 걸쳐 옅어진다 — 흰 바탕이 번쩍이지 않게. 옅어지는 동안에도 탭은 이미
///   아래 웹으로 간다(웹 헤더 뒤로가기가 0.5초 동안 먹통이 되지 않게).
/// - 다시 덮을 때(재시도·새로 불러오기)는 바로 덮는다 — 오류 화면이 사라지는 순간 빈 웹이 비치지 않게.
/// 화면에서 빼지 않고 투명도만 바꾸는 이유: 빠지는 중인 뷰는 마지막 상태(탭을 막는 상태)로 그려져서다.
struct WebLoadingOverlay: View {
    let isLoading: Bool

    static let fadeDuration: Double = 0.5

    var body: some View {
        ZStack {
            Color.component.background.default
            if isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isLoading ? 1 : 0)
        .allowsHitTesting(isLoading)
        .accessibilityHidden(!isLoading)
        .animation(isLoading ? nil : .easeOut(duration: Self.fadeDuration), value: isLoading)
    }
}

/// 첫 응답 전 빈 웹 위에 얹는 스피너. 덮개와 달리 웹을 가리거나 탭을 막지 않는다.
///
/// - `appearDelay` 뒤에 나타난다 — 빨리 오는 응답에서 스피너가 번쩍이지 않게(웹 Spinner와 같은 0.15초).
/// - 걷힐 때는 화면에서 바로 빠진다. 다시 나타날 때마다 새로 만들어져 늦춤도 다시 적용된다.
struct WebFirstResponseSpinner: View {
    static let appearDelay: Duration = .milliseconds(150)
    static let fadeInDuration: Double = 0.15

    @State private var isVisible = false

    var body: some View {
        ProgressView()
            .controlSize(.large)
            .opacity(isVisible ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .task {
                try? await Task.sleep(for: Self.appearDelay)
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: Self.fadeInDuration)) { isVisible = true }
            }
    }
}

#Preview("첫 응답 전 스피너") {
    WebFirstResponseSpinner()
        .background(Color.primitive.bw.trueWhite)
}
