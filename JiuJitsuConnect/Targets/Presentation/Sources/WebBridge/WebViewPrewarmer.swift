//
//  WebViewPrewarmer.swift
//  Presentation
//
//  앱을 켠 뒤 처음 만드는 WKWebView는 웹킷 초기화·웹 프로세스 띄우기 때문에 메인 스레드를 오래 붙잡는다.
//  그림이 멈춰 있는 스플래시 동안 웹뷰 하나를 미리 만들어 이 비용을 먼저 치러 두면,
//  인사 장면이 움직이는 중에 커뮤니티 웹뷰가 만들어지고 로드돼도 덜 끊긴다(#207).
//

import WebKit

@MainActor
enum WebViewPrewarmer {
    private static var webView: WKWebView?
    private static var didPrewarm = false

    /// 앱 실행 중 한 번만 띄운다. 실제 웹뷰가 만들어지면 `release()`로 놓아준다
    static func prewarm() {
        guard !didPrewarm else { return }
        didPrewarm = true

        let configuration = WKWebViewConfiguration()
        // 실제 웹뷰(BridgeWebView)와 같은 데이터스토어를 써야 네트워크 프로세스까지 함께 데워진다
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        // 빈 문서라도 불러야 웹 콘텐츠 프로세스가 뜬다
        webView.loadHTMLString("", baseURL: nil)
        self.webView = webView

        // 로그인 화면으로 가면 웹뷰가 한동안 안 생긴다. 쓰지 않을 프로세스를 오래 붙잡지 않게 시간이 지나면 놓아준다
        Task {
            try? await Task.sleep(for: .seconds(15))
            release()
        }
    }

    static func release() {
        webView = nil
    }
}
