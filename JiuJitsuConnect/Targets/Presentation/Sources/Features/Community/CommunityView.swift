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

    public var body: some View {
        ZStack {
            if let url = store.url {
                CommunityWebView(
                    url: url,
                    loadToken: store.loadToken,
                    onLoadingStarted: { store.send(.internal(.loadingStarted)) },
                    onLoadingFinished: { store.send(.internal(.loadingFinished)) },
                    onLoadingFailed: { store.send(.internal(.loadingFailed)) }
                )
            }

            if store.isLoading {
                loadingOverlay
            }

            if store.hasError {
                errorOverlay
            }
        }
        .background(Color.component.background.default)
        .onAppear { store.send(.view(.onAppear)) }
    }

    private var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.component.background.default)
    }

    private var errorOverlay: some View {
        VStack(spacing: 12) {
            Text("페이지를 불러올 수 없어요")
                .font(.pretendard.bodyM)
            Button("다시 시도") {
                store.send(.view(.retryTapped))
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
    let onLoadingStarted: () -> Void
    let onLoadingFinished: () -> Void
    let onLoadingFailed: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.load(url: url, token: loadToken, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed
        )
        context.coordinator.load(url: url, token: loadToken, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var onLoadingStarted: () -> Void
        private var onLoadingFinished: () -> Void
        private var onLoadingFailed: () -> Void

        private var lastLoadedURL: URL?
        private var lastLoadToken: UUID?

        init(
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void,
            onLoadingFailed: @escaping () -> Void
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
            self.onLoadingFailed = onLoadingFailed
        }

        func update(
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void,
            onLoadingFailed: @escaping () -> Void
        ) {
            self.onLoadingStarted = onLoadingStarted
            self.onLoadingFinished = onLoadingFinished
            self.onLoadingFailed = onLoadingFailed
        }

        func load(url: URL, token: UUID, in webView: WKWebView) {
            // URL이 바뀌었거나 retry 토큰이 갱신된 경우에만 reload.
            guard lastLoadedURL != url || lastLoadToken != token else { return }
            lastLoadedURL = url
            lastLoadToken = token
            webView.load(URLRequest(url: url))
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingStarted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingFinished()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Log.trace("Community webview didFail: \(error)", category: .network, level: .error)
            onLoadingFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Log.trace("Community webview didFailProvisionalNavigation: \(error)", category: .network, level: .error)
            onLoadingFailed()
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
