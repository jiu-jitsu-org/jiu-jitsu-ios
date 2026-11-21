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
    // 머리줄 바탕이 비어 웹이 그 뒤까지 깔려 있는지(웹 유리 면). 그러면 웹 딤이 머리줄 · 상태바 자리까지 이미 덮으므로
    // 막을 머리줄 글자 · 아이콘 모양으로만 깐다 — 통째로 깔면 그 자리만 두 번 어두워진다.
    var webDimsBehind = false

    func body(content: Content) -> some View {
        content
            // 손가락만 막으면 VoiceOver는 막 아래 버튼(종·검색)을 그대로 누른다 — 시트가 열린 동안은 읽지도 않게.
            .accessibilityHidden(isDimmed)
            .overlay {
                // 웹 딤과 같은 색(overlay/scrim · 검정 40%)·같은 0.2초 페이드. 머리줄 버튼은 막만 받고 눌리지 않는다.
                Group {
                    if webDimsBehind {
                        scrim.mask { content }
                    } else {
                        scrim.ignoresSafeArea(edges: .top)
                    }
                }
                .opacity(isDimmed ? 1 : 0)
                .contentShape(Rectangle())
                .allowsHitTesting(isDimmed)
                .animation(.easeInOut(duration: 0.2), value: isDimmed)
                .accessibilityHidden(true)
            }
    }

    private var scrim: Color { Color.component.bottomSheet.selected.container.scrim }
}

extension View {
    func webSheetHeaderDim(_ isDimmed: Bool, webDimsBehind: Bool = false) -> some View {
        modifier(WebSheetHeaderDim(isDimmed: isDimmed, webDimsBehind: webDimsBehind))
    }
}
