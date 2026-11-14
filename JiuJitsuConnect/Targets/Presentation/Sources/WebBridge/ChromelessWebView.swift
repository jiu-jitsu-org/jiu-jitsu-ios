//
//  ChromelessWebView.swift
//  Presentation
//
//  BridgeWebView가 쓰는 WKWebView. 키보드 위 기본 입력 바를 없애고, 겹치는 안전 영역이 바뀌면 알린다.
//

import WebKit

/// 시스템 기본 입력 액세서리 바(키보드 위 위/아래/완료 회색 폼 어시스턴트)를 제거한 WKWebView.
/// 웹이 자체 하단 툴바(사진/태그)를 키보드 위에 띄우므로 시스템 바는 불필요하고, 없는 편이 깔끔하다.
final class ChromelessWebView: WKWebView {
    override var inputAccessoryView: UIView? { nil }

    // 크기·창이 바뀔 때마다 실제로 겹치는 안전 영역을 넘긴다(WebSafeAreaInsets). 같은 값은 받는 쪽이 거른다.
    // 웹뷰의 자리·크기는 웹뷰 자신의 레이아웃에서 가장 확실히 잡히므로 여기서 잰다.
    var onSafeAreaMeasured: (@MainActor (WebSafeAreaInsets) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        reportSafeArea()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportSafeArea()
    }

    private func reportSafeArea() {
        // 창에 막 붙어 크기가 0인 순간은 재지 않는다 — 아래가 0으로 잘못 잡힌다.
        guard let onSafeAreaMeasured, !bounds.isEmpty, let insets = WebSafeAreaInsets.measured(for: self) else { return }
        onSafeAreaMeasured(insets)
    }
}
