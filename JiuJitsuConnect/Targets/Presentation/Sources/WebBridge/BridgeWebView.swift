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
    // 고정 셸(h-dvh + overflow:hidden) 화면에서, 키보드가 메인 문서를 위로 스크롤해 헤더가
    // 화면 밖으로 밀리는 것을 막기 위해 메인 스크롤뷰 세로 오프셋을 0으로 고정한다.
    var locksDocumentScroll: Bool = false
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

    // 웹뷰를 컨테이너 UIView로 감싼다. 직접 WKWebView를 반환하지 않는 이유는
    // 하단을 컨테이너의 keyboardLayoutGuide에 고정해 키보드만큼 높이를 줄이기 위해서다.
    // (아래 makeUIView 주석 참고)
    func makeUIView(context: Context) -> UIView {
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

        // 시스템 기본 입력 액세서리 바(위/아래/완료 회색 바)를 제거한다. 웹이 자체 하단 툴바
        // (사진/태그)를 키보드 위에 띄우므로 시스템 바는 불필요하고, 없는 편이 깔끔하다.
        let webView = ChromelessWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // 오버스크롤/바운스 영역에 WKWebView 기본 회색이 비치지 않도록 웹 콘텐츠(#ffffff)와
        // 동일한 불투명 흰색으로 맞춘다. (CommunityDetailView 배경도 흰색)
        webView.isOpaque = true
        webView.backgroundColor = UIColor(Color.primitive.bw.trueWhite)
        webView.scrollView.backgroundColor = UIColor(Color.primitive.bw.trueWhite)

        #if DEBUG || BETA
        // Safari > 개발자용 메뉴에서 이 웹뷰를 인스펙트할 수 있게 허용한다. (DEBUG/BETA 빌드)
        webView.isInspectable = true
        #endif

        context.coordinator.attach(webView: webView)
        // 고정 셸(상세): 키보드가 문서를 위로 스크롤해 헤더가 화면 밖으로 밀리는 것을 막는다.
        if locksDocumentScroll {
            context.coordinator.enableDocumentScrollLock(on: webView.scrollView)
        }

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
            context.coordinator.bind(refreshControl: refreshControl)
        }

        // 키보드가 뜨면 웹뷰 프레임 자체를 키보드 높이만큼 줄여(웹뷰를 키보드 위로 리사이즈)
        // layout/visual viewport를 축소한다. 그래야 웹(고정 셸 + 100dvh)의 입력바가 키보드 위에
        // 붙고, env(safe-area-inset-bottom)이 0이 되어 하단 여백/회색이 사라지며, 헤더는 고정되고
        // 본문만 스크롤된다. WKWebView는 viewport `interactive-widget=resizes-content` 지원이
        // 불안정해 레이아웃 뷰포트가 안 줄어들므로, 네이티브 프레임 리사이즈로 키보드를 처리한다.
        let container = KeyboardAvoidingWebContainer()
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        container.pinWebView(webView)

        context.coordinator.load(url: url, token: loadToken)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.update(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed,
            onBridgeMessage: onBridgeMessage,
            onOutboundDelivered: onOutboundDelivered
        )
        context.coordinator.load(url: url, token: loadToken)
        context.coordinator.flushOutbox(outbox)
    }

    static func dismantleUIView(_ container: UIView, coordinator: Coordinator) {
        // 핸들러를 정리해 WKUserContentController가 잔존 참조를 들고 있지 않도록 한다.
        coordinator.webView?.configuration.userContentController
            .removeScriptMessageHandler(forName: WebBridge.appBridgeHandlerName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
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

        // 로드·아웃바운드 주입·리프레시 등에서 공용으로 쓰는 webView 약한 참조.
        // (컨테이너로 감싸 makeUIView가 webView를 직접 반환하지 않으므로 직접 보관한다.)
        private(set) weak var webView: WKWebView?
        private weak var refreshControl: UIRefreshControl?
        // 현재 로드가 풀다운 리프레시로 시작됐는지. true면 전면 로딩 오버레이를
        // 띄우지 않고 리프레시 스피너만 유지한다.
        private var isRefreshing = false
        // 고정 셸(상세) 웹뷰에서 키보드가 메인 문서를 위로 스크롤해 헤더가 화면 밖으로 밀리는 것을
        // 막기 위해, 메인 스크롤뷰의 세로 오프셋을 0으로 고정할지 여부.
        private var locksDocumentScroll = false

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

        func load(url: URL, token: UUID) {
            guard let webView else { return }
            // URL이 바뀌었거나 retry 토큰이 갱신된 경우에만 reload.
            guard lastLoadedURL != url || lastLoadToken != token else { return }
            lastLoadedURL = url
            lastLoadToken = token
            // 재로드(재시도) 시 웹 컨텍스트가 초기화되므로 전달 기록도 비운다.
            // 재로드 후 다시 WEBVIEW_READY가 오면 초기 동기화가 새로 일어난다.
            deliveredOutboundIDs.removeAll()
            webView.load(URLRequest(url: url))
        }

        // 로드·아웃바운드·키보드 처리에 쓸 webView를 보관한다.
        func attach(webView: WKWebView) {
            self.webView = webView
        }

        // 고정 셸 화면에서 메인 문서 스크롤을 0에 고정한다. 키보드가 포커스된 입력칸을 보이려
        // 문서를 위로 스크롤(contentOffset.y>0)해 헤더가 화면 밖으로 밀리는 것을 되돌려 막는다.
        // (웹은 overflow:hidden이라 메인 문서는 스크롤될 일이 없고, 본문은 별도 스크롤러로 스크롤된다.)
        func enableDocumentScrollLock(on scrollView: UIScrollView) {
            locksDocumentScroll = true
            scrollView.delegate = self
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard locksDocumentScroll, scrollView.contentOffset.y != 0 else { return }
            scrollView.contentOffset.y = 0
        }

        // 풀다운 리프레시 컨트롤을 보관한다.
        func bind(refreshControl: UIRefreshControl) {
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
        func flushOutbox(_ outbox: [WebBridgeOutboundEnvelope]) {
            guard let webView else { return }
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
            // 해석 결과와 별개로, 웹이 보낸 원본을 먼저 남긴다(파싱 실패·계약 위반도 추적 가능하도록).
            WebBridge.logInboundRaw(message.body)
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

/// 키보드가 뜨면 웹뷰 프레임을 키보드 상단까지 줄이고, 내리면 화면 바닥까지 복귀시키는 컨테이너.
///
/// 웹뷰 프레임을 키보드만큼 줄이면 웹의 100dvh/고정 셸이 키보드 위 영역으로 맞춰져 입력바가
/// 키보드 위에 붙고 헤더는 고정된다. `keyboardLayoutGuide.topAnchor`에만 묶으면 키보드 해제 후
/// 가이드가 하단 safe area만큼 위에 머물러 흰 여백이 남으므로, 가이드 제약은 항상 살려두되
/// (키보드 추적 + 위로 띄움) required보다 한 단계 낮추고, 키보드가 없을 때만 바닥 고정 제약
/// (required)을 켜서 강제 복귀시킨다.
private final class KeyboardAvoidingWebContainer: UIView {
    private var bottomToBottomEdge: NSLayoutConstraint?

    func pinWebView(_ webView: UIView) {
        // 키보드가 떠 있는 동안 가이드가 키보드만 추적하도록(하단 safe area 미포함) 한다.
        keyboardLayoutGuide.usesBottomSafeArea = false
        // 항상 활성 → ① 가이드가 키보드를 추적하도록 engage ② 키보드 위로 웹뷰를 띄움.
        //   required보다 낮춰, 키보드 없을 때 아래 바닥 제약이 우선하게 한다.
        let toKeyboard = webView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        toKeyboard.priority = UILayoutPriority(999)
        // 키보드가 없을 때만 켜서 웹뷰를 화면 바닥까지 강제 복귀(잔류 여백 제거).
        let toBottomEdge = webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomToBottomEdge = toBottomEdge
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toKeyboard
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 가이드 상단이 하단 safe area보다 충분히 위에 있으면 키보드가 실제로 떠 있는 것으로 본다.
        // 키보드 ↑이면 바닥 고정을 풀어 웹뷰가 키보드 위로 따라 올라가게 하고,
        // 키보드 ↓이면 바닥 고정을 켜서 잔류 여백 없이 복귀시킨다.
        let distanceFromBottom = bounds.maxY - keyboardLayoutGuide.layoutFrame.minY
        let keyboardVisible = distanceFromBottom > safeAreaInsets.bottom + 8
        let shouldPinBottom = !keyboardVisible
        guard bottomToBottomEdge?.isActive != shouldPinBottom else { return }
        bottomToBottomEdge?.isActive = shouldPinBottom
    }
}

/// 시스템 기본 입력 액세서리 바(키보드 위 위/아래/완료 회색 폼 어시스턴트)를 제거한 WKWebView.
/// 웹이 자체 하단 툴바(사진/태그)를 키보드 위에 띄우므로 시스템 바는 불필요하고, 없는 편이 깔끔하다.
private final class ChromelessWebView: WKWebView {
    override var inputAccessoryView: UIView? { nil }
}
