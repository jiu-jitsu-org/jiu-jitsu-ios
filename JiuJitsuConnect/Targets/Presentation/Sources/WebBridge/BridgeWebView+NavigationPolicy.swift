//
//  BridgeWebView+NavigationPolicy.swift
//  Presentation
//
//  BridgeWebView 코디네이터의 메인 프레임 이동 정책과 화면을 쌓는 메시지 구분. BridgeWebView.swift에서 옮겨 왔다(#431, 파일 길이).
//

import UIKit
import WebKit
import CoreKit

// MARK: - 메인 프레임 이동 정책

extension BridgeWebView.Coordinator {
    /// 이동 정책이 막은 로드의 실패 알림이면 true를 돌려주고 표시를 지운다. WebKit은 "정책 변경으로 중단"(102)으로
    /// 알리지만, 취소(-999)로 오는 경우도 같은 것으로 본다 — 표시는 이 코디네이터가 막았을 때만 켜진다.
    func consumeNavigationPolicyCancel(_ error: Error) -> Bool {
        guard didCancelMainFrameNavigation else { return false }
        didCancelMainFrameNavigation = false
        let error = error as NSError
        return (error.domain == "WebKitErrorDomain" && error.code == 102) || error.code == NSURLErrorCancelled
    }

    // 메인 프레임 이동은 앱 웹 주소만 웹뷰에서 연다. 바깥 주소는 앱 위 브라우저, 전화 · 메일은 시스템으로 넘긴다.
    // 새 창(targetFrame nil)은 createWebViewWith가, iframe 이동은 그 문서가 맡으므로 그대로 둔다.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.targetFrame?.isMainFrame == true, let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let route = WebEnvironment.mainFrameRoute(for: url)
        didCancelMainFrameNavigation = route != .webView
        decisionHandler(route == .webView ? .allow : .cancel)
        switch route {
        case .webView: break
        case .inAppBrowser: openExternal(url, from: webView)
        case .system: UIApplication.shared.open(url)
        case .blocked: Log.trace("Bridge webview 이동 무시(지원하지 않는 scheme): \(url.scheme ?? "")", category: .view, level: .info)
        }
    }
}

extension WebBridgeInboundMessage {
    /// 이 웹뷰 위에 네이티브 화면(회원 프로필 · 서브뷰)을 쌓는 요청인지.
    var stacksScreenOverWebView: Bool {
        switch self {
        case .openUserProfile, .openSubview: true
        default: false
        }
    }
}
