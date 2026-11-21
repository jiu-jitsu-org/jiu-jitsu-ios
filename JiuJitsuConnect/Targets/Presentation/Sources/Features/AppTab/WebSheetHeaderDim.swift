//
//  WebSheetHeaderDim.swift
//  Presentation
//
//  탭 첫 화면의 웹이 아래 시트(지역 고르기 등)를 열면 웹은 자기 영역만 어둡게 덮는다.
//  앱이 그린 머리줄·상태바는 밝게 남아 한 화면이 위아래로 갈려 보였다 — 시트가 열린 동안(SET_SHEET_OPEN)
//  머리줄 위에도 같은 어두운 막을 깔아 웹 딤과 한 면으로 잇는다.
//

import SwiftUI
import DesignSystem

struct WebSheetHeaderDim: ViewModifier {
    let isDimmed: Bool

    func body(content: Content) -> some View {
        content
            // 손가락만 막으면 VoiceOver는 막 아래 버튼(종·검색)을 그대로 누른다 — 시트가 열린 동안은 읽지도 않게.
            .accessibilityHidden(isDimmed)
            .overlay {
                // 웹 딤과 같은 색(overlay/scrim · 검정 40%)·같은 0.2초 페이드. 머리줄 버튼은 막만 받고 눌리지 않는다.
                Color.component.bottomSheet.selected.container.scrim
                    .ignoresSafeArea(edges: .top)
                    .opacity(isDimmed ? 1 : 0)
                    .allowsHitTesting(isDimmed)
                    .animation(.easeInOut(duration: 0.2), value: isDimmed)
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    func webSheetHeaderDim(_ isDimmed: Bool) -> some View {
        modifier(WebSheetHeaderDim(isDimmed: isDimmed))
    }
}
