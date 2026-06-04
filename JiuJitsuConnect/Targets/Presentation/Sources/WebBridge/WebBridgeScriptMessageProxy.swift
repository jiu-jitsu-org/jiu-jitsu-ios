//
//  WebBridgeScriptMessageProxy.swift
//  Presentation
//
//  `WKUserContentController`는 등록된 메시지 핸들러를 strong 참조한다.
//  Coordinator를 직접 등록하면 (webView → configuration → userContentController → Coordinator)
//  경로로 강한 참조가 생겨 웹뷰 전체가 누수될 수 있다.
//  약한 참조 프록시를 사이에 끼워 그 사슬을 끊는다.
//

import WebKit

final class WebBridgeScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
