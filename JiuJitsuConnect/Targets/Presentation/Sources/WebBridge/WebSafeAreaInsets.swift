//
//  WebSafeAreaInsets.swift
//  Presentation
//
//  웹뷰가 겹치는 기기 안전 영역(상태바·홈 막대 자리)을 웹에 CSS 변수로 알린다.
//
//  WKWebView는 `env(safe-area-inset-*)`를 문서를 다 불러온 뒤에도 0으로 두다가 나중에 채우는 때가 있다
//  (WebKit 191872). 그 전에 그려진 첫 화면은 헤더가 상태바 밑에 붙었다가 내려온다(상세 웹에서 실측: 다 불러온
//  시점에 네이티브 62pt · CSS 0px). 네이티브는 값을 미리 알므로 문서가 시작될 때 `--app-safe-area-inset-top`
//  · `--app-safe-area-inset-bottom`으로 넣고, 웹은 이 변수를 먼저 읽고 없으면(브라우저) `env()`로 돌아간다.
//

import UIKit
import WebKit

/// 웹뷰가 실제로 겹치는 안전 영역. 기기 전체 값이 아니다 — 머리줄 아래 놓인 탭 첫 화면 웹은 위가 0이고,
/// 키보드 위로 줄어든 웹뷰는 아래가 0이다(`env()`가 주는 값과 같은 뜻).
struct WebSafeAreaInsets: Equatable {
    var top: CGFloat
    var bottom: CGFloat

    static let topVariable = "--app-safe-area-inset-top"
    static let bottomVariable = "--app-safe-area-inset-bottom"

    /// 웹뷰를 화면에 붙이기 전, 놓일 자리로 짐작한 값. 문서 시작 스크립트에 넣어 첫 그림부터 맞게 한다.
    /// 세로 고정 앱이라 창의 안전 영역은 기기마다 정해져 있다. 창을 못 찾으면 0 — 웹은 `env()`와 같은 처지가 된다.
    @MainActor
    static func expected(coversStatusBar: Bool) -> WebSafeAreaInsets {
        let windowInsets = keyWindow?.safeAreaInsets ?? .zero
        return WebSafeAreaInsets(top: coversStatusBar ? windowInsets.top : 0, bottom: windowInsets.bottom)
    }

    /// 화면에 붙은 웹뷰가 지금 겹치는 값. 창에 없으면(닫히는 중 · 아직 안 붙음) nil.
    @MainActor
    static func measured(for view: UIView) -> WebSafeAreaInsets? {
        guard let window = view.window else { return nil }
        let frame = view.convert(view.bounds, to: window)
        let insets = window.safeAreaInsets
        // 탭 바 움직임 등으로 생기는 소수점 흔들림에 매번 웹을 다시 그리지 않게 정수 pt로 맞춘다.
        let top = min(max(insets.top - frame.minY, 0), insets.top).rounded()
        let bottom = min(max(frame.maxY - (window.bounds.maxY - insets.bottom), 0), insets.bottom).rounded()
        return WebSafeAreaInsets(top: top, bottom: bottom)
    }

    /// 문서가 만들어지자마자(다른 내용을 읽기 전) 값을 넣는 스크립트. 웹뷰를 만들 때 한 번 붙인다.
    var documentStartScript: WKUserScript {
        WKUserScript(source: applyScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    /// 지금 문서에 값을 넣는 스크립트. 루트 요소의 인라인 스타일에만 쓴다 — React가 다루지 않는 속성이라 하이드레이션과 부딪히지 않는다.
    var applyScript: String {
        "(function(){var s=document.documentElement&&document.documentElement.style;if(!s)return;"
            + "s.setProperty('\(Self.topVariable)','\(Self.cssPixels(top))');"
            + "s.setProperty('\(Self.bottomVariable)','\(Self.cssPixels(bottom))');})();"
    }

    private static func cssPixels(_ value: CGFloat) -> String {
        String(format: "%.1fpx", Double(value))
    }

    @MainActor
    private static var keyWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
