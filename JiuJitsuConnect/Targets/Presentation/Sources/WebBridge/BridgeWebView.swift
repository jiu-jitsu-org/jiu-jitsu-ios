//
//  BridgeWebView.swift
//  Presentation
//
//  AppBridge를 등록한 WKWebView 공용 호스트(UIViewRepresentable).
//  커뮤니티 리스트와 게시글 상세(서브뷰)가 동일한 설정·브릿지 플러밍을 공유하도록 한 곳에 둔다.
//  두 웹뷰는 같은 WKWebsiteDataStore(.default())를 써서 로그인 세션 쿠키(httpOnly 포함)를 공유한다.
//  (iOS 15+부터 default 데이터스토어를 쓰는 웹뷰들은 자동으로 동일 웹 콘텐츠 프로세스를
//   공유하므로 WKProcessPool은 더 이상 설정하지 않는다.)
//

import SwiftUI
import WebKit
import DesignSystem
import CoreKit

struct BridgeWebView: UIViewRepresentable {
    let url: URL
    // 같은 URL로 강제 reload를 트리거하기 위한 토큰.
    let loadToken: UUID
    // 네이티브 → 웹으로 전달 대기 중인 브릿지 메시지.
    let outbox: [WebBridgeOutboundEnvelope]
    // 좌우 스와이프 백/포워드 제스처 허용 여부. 상세 서브뷰는 웹 자체 헤더로 뒤로가기를
    // 처리하므로 false로 두어 제스처 충돌을 피한다.
    var allowsBackForwardNavigationGestures: Bool = true
    // 풀다운 리프레시 사용 여부. 상세 서브뷰는 스크롤/상태 보존을 위해 끈다.
    var enablesPullToRefresh: Bool = true
    let onLoadingStarted: () -> Void
    let onLoadingFinished: () -> Void
    let onLoadingFailed: () -> Void
    // 웹 → 네이티브 인바운드 메시지(AppBridge) 수신 콜백.
    let onBridgeMessage: (WebBridgeInboundMessage) -> Void
    // 아웃바운드 메시지를 evaluateJavaScript로 실제 전달한 뒤 호출.
    let onOutboundDelivered: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed,
            onBridgeMessage: onBridgeMessage,
            onOutboundDelivered: onOutboundDelivered
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // 리스트·상세 웹뷰가 로그인 세션 쿠키(httpOnly 포함)를 공유하도록 영구 default 데이터스토어를 강제한다.
        config.websiteDataStore = .default()

        // 웹 → 네이티브 단일 라우터(AppBridge) 등록.
        // WKUserContentController가 핸들러를 strong 참조하므로 약한 프록시를 끼워 누수를 막는다.
        let contentController = WKUserContentController()
        contentController.add(
            WebBridgeScriptMessageProxy(delegate: context.coordinator),
            name: WebBridge.appBridgeHandlerName
        )
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        #if DEBUG
        // Safari > 개발자용 메뉴에서 이 웹뷰를 인스펙트할 수 있게 허용한다. (DEBUG 전용)
        webView.isInspectable = true
        #endif

        // 풀다운 리프레시: 페이지를 가리는 전면 로딩 오버레이 대신 네이티브 스피너만 노출한다.
        if enablesPullToRefresh {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = UIColor(Color.semantic.interactive.primary)
            refreshControl.addTarget(
                context.coordinator,
                action: #selector(Coordinator.handleRefresh),
                for: .valueChanged
            )
            webView.scrollView.refreshControl = refreshControl
            context.coordinator.bind(webView: webView, refreshControl: refreshControl)
        }

        context.coordinator.load(url: url, token: loadToken, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed,
            onBridgeMessage: onBridgeMessage,
            onOutboundDelivered: onOutboundDelivered
        )
        context.coordinator.load(url: url, token: loadToken, in: webView)
        context.coordinator.flushOutbox(outbox, in: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // 핸들러를 정리해 WKUserContentController가 잔존 참조를 들고 있지 않도록 한다.
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: WebBridge.appBridgeHandlerName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private var onLoadingStarted: () -> Void
        private var onLoadingFinished: () -> Void
        private var onLoadingFailed: () -> Void
        private var onBridgeMessage: (WebBridgeInboundMessage) -> Void
        private var onOutboundDelivered: (UUID) -> Void

        private var lastLoadedURL: URL?
        private var lastLoadToken: UUID?
        // 이미 evaluateJavaScript로 전달한 아웃바운드 id. updateUIView가 여러 번
        // 호출돼도 같은 메시지를 중복 주입하지 않도록 가드한다.
        private var deliveredOutboundIDs: Set<UUID> = []

        // 풀다운 리프레시용 약한 참조. target-action 콜백에는 델리게이트 메서드와 달리
        // webView가 인자로 오지 않아 직접 보관한다.
        private weak var webView: WKWebView?
        private weak var refreshControl: UIRefreshControl?
        // 현재 로드가 풀다운 리프레시로 시작됐는지. true면 전면 로딩 오버레이를
        // 띄우지 않고 리프레시 스피너만 유지한다.
        private var isRefreshing = false

        init(
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void,
            onLoadingFailed: @escaping () -> Void,
            onBridgeMessage: @escaping (WebBridgeInboundMessage) -> Void,
            onOutboundDelivered: @escaping (UUID) -> Void
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
            self.onLoadingFailed = onLoadingFailed
            self.onBridgeMessage = onBridgeMessage
            self.onOutboundDelivered = onOutboundDelivered
        }

        func update(
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void,
            onLoadingFailed: @escaping () -> Void,
            onBridgeMessage: @escaping (WebBridgeInboundMessage) -> Void,
            onOutboundDelivered: @escaping (UUID) -> Void
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
            self.onLoadingFailed = onLoadingFailed
            self.onBridgeMessage = onBridgeMessage
            self.onOutboundDelivered = onOutboundDelivered
        }

        func load(url: URL, token: UUID, in webView: WKWebView) {
            // URL이 바뀌었거나 retry 토큰이 갱신된 경우에만 reload.
            guard lastLoadedURL != url || lastLoadToken != token else { return }
            lastLoadedURL = url
            lastLoadToken = token
            // 재로드(재시도) 시 웹 컨텍스트가 초기화되므로 전달 기록도 비운다.
            // 재로드 후 다시 WEBVIEW_READY가 오면 초기 동기화가 새로 일어난다.
            deliveredOutboundIDs.removeAll()
            webView.load(URLRequest(url: url))
        }

        // 풀다운 리프레시 대상 webView·컨트롤을 보관한다.
        func bind(webView: WKWebView, refreshControl: UIRefreshControl) {
            self.webView = webView
            self.refreshControl = refreshControl
        }

        @objc func handleRefresh() {
            guard let webView else { return }
            isRefreshing = true
            // 리프레시로 웹 컨텍스트가 재초기화되므로 전달 기록을 비워
            // 재로드 후 WEBVIEW_READY 핸드셰이크에서 상태가 다시 동기화되게 한다.
            deliveredOutboundIDs.removeAll()
            webView.reload()
        }

        private func endRefreshing() {
            guard isRefreshing else { return }
            isRefreshing = false
            refreshControl?.endRefreshing()
        }

        // 대기열의 아웃바운드 메시지를 순서대로 웹에 주입한다.
        func flushOutbox(_ outbox: [WebBridgeOutboundEnvelope], in webView: WKWebView) {
            for envelope in outbox where !deliveredOutboundIDs.contains(envelope.id) {
                guard let script = envelope.message.makeJavaScript() else {
                    // 직렬화 실패한 메시지는 영구히 막히지 않도록 전달 처리해 대기열에서 제거한다.
                    deliveredOutboundIDs.insert(envelope.id)
                    onOutboundDelivered(envelope.id)
                    continue
                }
                deliveredOutboundIDs.insert(envelope.id)
                WebBridge.logOutbound(envelope.message)
                webView.evaluateJavaScript(script) { [weak self] _, error in
                    guard let self else { return }
                    if let error {
                        Log.trace("WebBridge outbound 전달 실패: \(error)", category: .network, level: .error)
                    }
                    self.onOutboundDelivered(envelope.id)
                }
            }
        }

        // MARK: WKScriptMessageHandler
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == WebBridge.appBridgeHandlerName else { return }
            guard let inbound = WebBridgeInboundMessage.decode(from: message.body) else { return }
            WebBridge.logInbound(inbound)
            onBridgeMessage(inbound)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 풀다운 리프레시 중에는 페이지를 가리는 전면 오버레이 대신 스피너만 유지한다.
            guard !isRefreshing else { return }
            onLoadingStarted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            endRefreshing()
            onLoadingFinished()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Log.trace("Bridge webview didFail: \(error)", category: .network, level: .error)
            endRefreshing()
            onLoadingFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Log.trace("Bridge webview didFailProvisionalNavigation: \(error)", category: .network, level: .error)
            endRefreshing()
            onLoadingFailed()
        }

        // HTTP 4xx/5xx는 WKWebView 관점에서 "정상 로드"라 didFail이 호출되지 않는다.
        // 메인 프레임 응답의 상태 코드를 직접 검사해 에러로 처리한다.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if
                navigationResponse.isForMainFrame,
                let http = navigationResponse.response as? HTTPURLResponse,
                !(200..<400).contains(http.statusCode)
            {
                Log.trace("Bridge webview HTTP error: \(http.statusCode)", category: .network, level: .error)
                decisionHandler(.cancel)
                endRefreshing()
                onLoadingFailed()
                return
            }
            decisionHandler(.allow)
        }
    }
}
