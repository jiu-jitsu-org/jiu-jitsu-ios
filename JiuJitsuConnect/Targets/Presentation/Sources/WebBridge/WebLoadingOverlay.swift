//
//  WebLoadingOverlay.swift
//  Presentation
//
//  웹뷰를 덮는 로딩 덮개(홈 피드·쌓이는 웹 화면·대회 탭 공용, #261).
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
