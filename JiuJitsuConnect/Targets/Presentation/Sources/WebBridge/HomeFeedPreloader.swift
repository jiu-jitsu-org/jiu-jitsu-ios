//
//  HomeFeedPreloader.swift
//  Presentation
//
//  스플래시가 떠 있는 동안 홈 피드 웹을 미리 불러 두고, 홈 웹뷰(BridgeWebView, `.list`)가 그 웹뷰를 이어받게 한다(#270).
//  지금까지는 스플래시가 끝나야 홈 웹뷰가 생겨, 웹 연결·서버 렌더링·스크립트 받기가 모두 스플래시 뒤에 차례로 붙었다.
//
//  미리 불러 둘 토큰이 없으면(로그인 전, 저장된 토큰 만료) 예전처럼 빈 웹뷰만 만들어 웹킷을 데워 둔다.
//  앱을 켠 뒤 처음 만드는 WKWebView는 웹킷 초기화·웹 프로세스 띄우기 때문에 메인 스레드를 오래 붙잡으므로,
//  그림이 멈춰 있는 스플래시 동안 이 비용을 치러 두면 인사 장면이 움직이는 중에 덜 끊긴다(#207).
//

import WebKit
import CoreKit

@MainActor
enum HomeFeedPreloader {
    /// 미리 불러 둔 홈 피드. 홈 웹뷰가 이어받거나 버리면 비운다.
    private static var pending: HomeFeedPreload?
    /// 웹킷만 데워 두는 빈 웹뷰(#207)
    private static var warmWebView: WKWebView?
    private static var releaseTask: Task<Void, Never>?

    /// 빈 웹뷰를 하나 만들어 웹킷을 데워 둔다. 홈 피드를 미리 불러 두는 중이면 그 웹뷰가 같은 일을 하므로 건너뛴다.
    static func prewarm() {
        guard warmWebView == nil, pending == nil else { return }
        let configuration = WKWebViewConfiguration()
        // 실제 웹뷰(BridgeWebView)와 같은 데이터스토어를 써야 네트워크 프로세스까지 함께 데워진다
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        // 빈 문서라도 불러야 웹 콘텐츠 프로세스가 뜬다
        webView.loadHTMLString("", baseURL: nil)
        warmWebView = webView
        scheduleRelease()
    }

    /// 홈 피드를 미리 불러 둔다. 세션 쿠키를 먼저 심어 서버 렌더링이 처음부터 로그인 상태로 되게 한다.
    static func preload(url: URL, accessToken: String) {
        guard pending == nil else { return }
        let preload = HomeFeedPreload(url: url)
        pending = preload
        // 실제 설정의 웹뷰가 웹킷을 데우므로 빈 웹뷰는 더 붙잡지 않는다
        warmWebView = nil
        Log.trace("🏠 home-preload: 홈 피드 미리 불러오기 시작", category: .view, level: .info)
        let webView = preload.webView
        Task { @MainActor in
            await WebSessionCookie.sync(
                accessToken: accessToken,
                for: url,
                into: webView.configuration.websiteDataStore.httpCookieStore
            )
            // 쿠키를 심는 사이 로그인 화면으로 가 버려졌으면 불러오지 않는다
            guard !preload.isDiscarded else { return }
            // 이어받은 홈 웹뷰와 같은 제한 시간 — 앱을 켤 때 서버가 멈춰 있으면 대개 이 요청이 걸린다
            webView.load(URLRequest(url: url, timeoutInterval: BridgeWebView.documentRequestTimeout))
        }
        scheduleRelease()
    }

    /// 홈 피드 웹뷰의 브릿지 기능 목록. 탭 바 밑까지 그리는 웹은 BridgeWebView가 시트 열림 알림을 덧붙인다(#314).
    static let capabilities: [WebBridgeCapability] = [.setSheetOpen]

    /// 홈 웹뷰가 미리 불러 둔 화면을 이어받는다. 주소·설정이 다르면 이어받지 않고 새로 만들게 둔다.
    static func take(url: URL, capabilities: [WebBridgeCapability]) -> HomeFeedPreload? {
        guard let preload = pending else { return nil }
        pending = nil
        // 미리 부를 때는 홈 피드와 같은 기능 알림만 넣으므로, 다른 설정이 필요한 웹뷰는 이어받을 수 없다
        guard preload.url == url, capabilities == Self.capabilities else {
            discard(preload)
            return nil
        }
        return preload
    }

    /// 로그인 화면으로 가는 등 홈이 생기지 않으면 미리 불러 둔 화면을 버린다.
    static func discard() {
        guard let preload = pending else { return }
        pending = nil
        discard(preload)
    }

    /// 실제 웹뷰가 생겼으니 데워 둔 빈 웹뷰는 놓아준다.
    static func releaseWarmWebView() {
        warmWebView = nil
    }

    private static func discard(_ preload: HomeFeedPreload) {
        preload.isDiscarded = true
        preload.webView.stopLoading()
        Log.trace("🏠 home-preload: 미리 불러 둔 홈 피드를 버림", category: .view, level: .info)
    }

    // 로그인 화면으로 가면 홈 웹뷰가 한동안 안 생긴다. 쓰지 않을 웹뷰를 오래 붙잡지 않게 시간이 지나면 놓아준다.
    private static func scheduleRelease() {
        releaseTask?.cancel()
        releaseTask = Task {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            warmWebView = nil
            discard()
        }
    }
}

/// 미리 불러 둔 홈 피드 웹뷰. 홈 웹뷰가 이어받기 전까지 오는 로딩·브릿지 이벤트를 순서대로 받아 두었다가 넘겨준다.
final class HomeFeedPreload {
    let url: URL
    let webView: WKWebView
    var isDiscarded = false
    private let recorder: HomeFeedPreloadRecorder

    @MainActor
    init(url: URL) {
        self.url = url
        let recorder = HomeFeedPreloadRecorder()
        self.recorder = recorder
        // 홈 웹뷰와 같은 설정으로 만든다(홈은 탭 바 밑까지 그리는 웹이라 시트 열림 알림만 쓴다, #314)
        // 홈 웹은 머리줄 아래 놓여 상태바를 덮지 않는다 — 홈 웹뷰(BridgeWebView)가 짐작하는 값과 같아야 한다.
        webView = BridgeWebView.makeWebView(
            capabilities: HomeFeedPreloader.capabilities,
            safeArea: .expected(coversStatusBar: false),
            messageHandler: recorder
        )
        webView.navigationDelegate = recorder
    }

    /// 홈 웹뷰의 코디네이터에 넘긴다. 받아 둔 이벤트를 순서대로 다시 보내고, 그 뒤 이벤트는 코디네이터가 직접 받는다.
    /// 화면을 그리는 도중(makeUIView) store가 바뀌지 않도록 다음 차례에 한다. 넘기기 전까지 오는 이벤트도
    /// 계속 받아 두었다가 함께 보내므로, 순서가 뒤집혀 로딩 덮개가 남는 일이 없다.
    @MainActor
    func handOff(to coordinator: BridgeWebView.Coordinator) {
        let webView = webView
        let recorder = recorder
        Task { @MainActor in
            webView.navigationDelegate = coordinator
            let contentController = webView.configuration.userContentController
            contentController.removeScriptMessageHandler(forName: WebBridge.appBridgeHandlerName)
            contentController.add(
                WebBridgeScriptMessageProxy(delegate: coordinator),
                name: WebBridge.appBridgeHandlerName
            )
            let events = recorder.takeEvents()
            Log.trace("🏠 home-preload: 홈 웹뷰가 이어받음(adopt) — 받아 둔 이벤트 \(events.count)개", category: .view, level: .info)
            for event in events {
                switch event {
                case .started:
                    coordinator.webView(webView, didStartProvisionalNavigation: nil)
                case .finished:
                    coordinator.webView(webView, didFinish: nil)
                case let .failed(error):
                    coordinator.webView(webView, didFail: nil, withError: error)
                case let .message(body):
                    coordinator.receiveBridgeMessage(body)
                }
            }
        }
    }
}

/// 이어받기 전까지 웹뷰의 내비게이션·브릿지 이벤트를 받아 두는 대리자.
private final class HomeFeedPreloadRecorder: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    enum Event {
        case started
        case finished
        case failed(Error)
        case message(Any)
    }

    private var events: [Event] = []

    func takeEvents() -> [Event] {
        defer { events.removeAll() }
        return events
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == WebBridge.appBridgeHandlerName else { return }
        Log.trace("🏠 home-preload: \(Self.messageType(of: message.body)) 받아 둠", category: .view, level: .info)
        events.append(.message(message.body))
    }

    // 로그용 메시지 종류. 웹은 봉투를 객체 또는 JSON 문자열로 보낸다.
    private static func messageType(of body: Any) -> String {
        var envelope = body as? [String: Any]
        if envelope == nil, let text = body as? String, let data = text.data(using: .utf8) {
            envelope = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        return envelope?["type"] as? String ?? "(알 수 없는 메시지)"
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        events.append(.started)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        events.append(.finished)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        events.append(.failed(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        events.append(.failed(error))
    }

    // HTTP 4xx/5xx는 WKWebView 관점에서 정상 로드라, 홈 웹뷰(BridgeWebView)와 같이 직접 실패로 처리한다.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.isForMainFrame,
           let http = navigationResponse.response as? HTTPURLResponse,
           !(200..<400).contains(http.statusCode) {
            decisionHandler(.cancel)
            events.append(.failed(URLError(.badServerResponse)))
            return
        }
        decisionHandler(.allow)
    }
}
