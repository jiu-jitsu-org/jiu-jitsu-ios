//
//  CommunityView.swift
//  Presentation
//
//  커뮤니티 탭 컨테이너 — WKWebView를 호스팅하고 로딩/에러 오버레이를 그린다.
//

import SwiftUI
import WebKit
import ComposableArchitecture
import DesignSystem
import CoreKit

public struct CommunityView: View {
    let store: StoreOf<CommunityFeature>

    public init(store: StoreOf<CommunityFeature>) {
        self.store = store
    }

    private enum Metrics {
        // 알림·검색 아이콘 버튼 2곳에서 공유
        static let trailingIconSize: CGFloat = 24
        static let trailingIconButtonSize: CGFloat = 40
        // 플로팅 버튼 trailing·bottom padding 2곳에서 공유
        static let floatingButtonPadding: CGFloat = 12
    }

    public var body: some View {
        VStack(spacing: 0) {
            gnb
            ZStack {
                if let url = store.url {
                    CommunityWebView(
                        url: url,
                        loadToken: store.loadToken,
                        outbox: store.outbox,
                        onLoadingStarted: { store.send(.internal(.loadingStarted)) },
                        onLoadingFinished: { store.send(.internal(.loadingFinished)) },
                        onLoadingFailed: { store.send(.internal(.loadingFailed)) },
                        onBridgeMessage: { store.send(.internal(.bridgeMessageReceived($0))) },
                        onOutboundDelivered: { store.send(.internal(.outboundDelivered(id: $0))) }
                    )
                }

                if store.isLoading {
                    loadingOverlay
                }

                if store.hasError {
                    errorOverlay
                }

                floatingWriteButton
            }
        }
        .background(Color.component.background.default)
        .onAppear { store.send(.view(.onAppear)) }
    }

    private var gnb: some View {
        // 디바이더(1pt)를 탭 콘텐츠보다 뒤 레이어에 깔아야
        // 탭 인디케이터(2pt)가 디바이더에 가려지지 않고 온전히 그려진다.
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.component.navibar.container.divider)
                .frame(height: 1)

            HStack(spacing: 0) {
                HStack(spacing: 16) {
                    ForEach(CommunityFeature.Tab.allCases, id: \.self) { tab in
                        tabButton(tab)
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Button {
                        store.send(.view(.notificationTapped))
                    } label: {
                        Assets.Common.Icon.bell.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metrics.trailingIconSize, height: Metrics.trailingIconSize)
                            .foregroundStyle(Color.component.header.iconButton)
                            .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.send(.view(.searchTapped))
                    } label: {
                        Assets.Common.Icon.search.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metrics.trailingIconSize, height: Metrics.trailingIconSize)
                            .foregroundStyle(Color.component.header.iconButton)
                            .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
        .frame(height: 44)
        .background(Color.component.header.background)
    }

    private func tabButton(_ tab: CommunityFeature.Tab) -> some View {
        let isSelected = store.selectedTab == tab
        return Button {
            store.send(.view(.tabSelected(tab)))
        } label: {
            Text(tab.title)
                .font(Font.pretendard.bodyM)
                .foregroundStyle(
                    isSelected
                    ? Color.component.tabBar.selected.text
                    : Color.component.tabBar.unselected.text
                )
                .frame(maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(
                            isSelected
                            ? Color.component.tabBar.selected.underline
                                : Color.clear
                        )
                        .frame(height: 2)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var floatingWriteButton: some View {
        Button {
            store.send(.view(.writeTapped))
        } label: {
            Assets.Common.Icon.pencilLine.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.semantic.primary.onPrimary)
                .frame(width: 48, height: 48)
                .background(
                    Capsule().fill(Color.semantic.interactive.primary)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, Metrics.floatingButtonPadding)
        .padding(.bottom, Metrics.floatingButtonPadding)
    }

    private var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.component.background.default)
    }

    private var errorOverlay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 13) {
                Text("잠시 문제가 생겼어요")
                    .font(.pretendard.bodyM)
                    .foregroundStyle(Color.component.errorState.default.titleText)
                Button {
                    store.send(.view(.retryTapped))
                } label: {
                    AppButtonConfiguration(title: "재시도", size: .medium)
                }
                .appButtonStyle(.neutral, size: .medium)
                .frame(height: 38)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.component.background.default)
    }
}

// MARK: - WKWebView Bridge

private struct CommunityWebView: UIViewRepresentable {
    let url: URL
    // 같은 URL로 강제 reload를 트리거하기 위한 토큰.
    let loadToken: UUID
    // 네이티브 → 웹으로 전달 대기 중인 브릿지 메시지.
    let outbox: [WebBridgeOutboundEnvelope]
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
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // 풀다운 리프레시: 페이지를 가리는 전면 로딩 오버레이 대신 네이티브 스피너만 노출한다.
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(Color.semantic.interactive.primary)
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl
        context.coordinator.bind(webView: webView, refreshControl: refreshControl)

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
                    if let error {
                        Log.trace("WebBridge outbound 전달 실패: \(error)", category: .network, level: .error)
                    }
                    self?.onOutboundDelivered(envelope.id)
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
            Log.trace("Community webview didFail: \(error)", category: .network, level: .error)
            endRefreshing()
            onLoadingFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Log.trace("Community webview didFailProvisionalNavigation: \(error)", category: .network, level: .error)
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
                Log.trace("Community webview HTTP error: \(http.statusCode)", category: .network, level: .error)
                decisionHandler(.cancel)
                endRefreshing()
                onLoadingFailed()
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Preview
#Preview {
    CommunityView(
        store: Store(initialState: CommunityFeature.State()) {
            CommunityFeature()
        }
    )
}
