//
//  TermsWebViewView.swift
//  Presentation
//
//  Created by suni on 5/18/26.
//

import SwiftUI
import WebKit
import ComposableArchitecture
import DesignSystem
import CoreKit

public struct TermsWebViewView: View {

    @Bindable var store: StoreOf<TermsWebViewFeature>

    public init(store: StoreOf<TermsWebViewFeature>) {
        self.store = store
    }

    @State private var isCloseButtonExpanded: Bool = true
    @State private var lastScrollOffset: CGFloat = 0
    // didFinish 이후에도 JS 렌더링(Notion 블록 등)이 더 진행되므로,
    // 사용자가 즉시 스크롤해 부분 렌더 상태를 보지 않도록 그레이스 시간을 둔다.
    @State private var isWebViewReady: Bool = false

    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                // WebView는 풀스크린(상태바·홈인디케이터 뒤까지)을 점유하고,
                // 스크롤 컨텐츠는 시스템 safe area + 닫기 버튼 영역만큼 inset을 두어
                // 컨텐츠가 상단 상태바나 하단 닫기 버튼에 가려지지 않도록 한다.
                TermsWKWebView(
                    url: store.url,
                    topContentInset: proxy.safeAreaInsets.top,
                    bottomContentInset: proxy.safeAreaInsets.bottom
                        + Style.expandedHeight
                        + Style.bottomPadding,
                    onScroll: { newOffset in
                        handleScroll(newOffset: newOffset)
                    },
                    onLoadFinish: {
                        // JS 렌더링 안정화를 위해 짧은 그레이스 시간 후 노출.
                        DispatchQueue.main.asyncAfter(deadline: .now() + Style.loadGracePeriod) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isWebViewReady = true
                            }
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .opacity(isWebViewReady ? 1 : 0)

            if !isWebViewReady {
                ProgressView()
                    .tint(Color.component.cta.dark.bg)
                    .scaleEffect(1.2)
            }
        }
        .overlay(alignment: .bottom) {
            closeButton
                .padding(.bottom, Style.bottomPadding)
                .opacity(isWebViewReady ? 1 : 0)
        }
        .background(
            Color.component.background.default
                .ignoresSafeArea()
        )
    }

    private var closeButton: some View {
        Button {
            store.send(.view(.closeButtonTapped))
        } label: {
            HStack(spacing: Style.textToIconSpacing) {
                if isCloseButtonExpanded {
                    Text("닫기")
                        .font(Font.pretendard.buttonM)
                        .foregroundStyle(Color.component.button.filled.defaultText)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                Image(systemName: "xmark")
                    .font(.system(size: Style.iconGlyphSize, weight: .semibold))
                    .frame(width: Style.iconSize, height: Style.iconSize)
                    .foregroundStyle(Color.component.button.filled.defaultText)
            }
            .padding(.leading, isCloseButtonExpanded ? Style.expandedLeading : 0)
            .padding(.trailing, isCloseButtonExpanded ? Style.expandedTrailing : 0)
            .padding(.vertical, isCloseButtonExpanded ? Style.expandedVerticalPadding : 0)
            .frame(
                minWidth: isCloseButtonExpanded ? nil : Style.collapsedSize,
                minHeight: isCloseButtonExpanded ? nil : Style.collapsedSize
            )
            .background(
                RoundedRectangle(
                    cornerRadius: isCloseButtonExpanded ? Style.expandedCornerRadius : Style.collapsedCornerRadius,
                    style: .continuous
                )
                .fill(Color.component.button.filled.defaultBg)
                .shadow(color: Style.shadowColor, radius: Style.shadowRadius, x: 0, y: Style.shadowY)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: Style.animationDuration), value: isCloseButtonExpanded)
    }

    private func handleScroll(newOffset: CGFloat) {
        // 부드러운 토글을 위해 작은 이동(미세 떨림)은 무시하고,
        // 스크롤 방향(아래/위)을 기준으로 버튼 상태를 결정한다.
        let delta = newOffset - lastScrollOffset
        let prevExpanded = isCloseButtonExpanded

        if newOffset <= Style.topThreshold {
            // 최상단 영역에서는 항상 확장 상태 유지
            if !isCloseButtonExpanded {
                isCloseButtonExpanded = true
            }
        } else if delta > Style.directionThreshold {
            // 아래로 스크롤 → 축소
            if isCloseButtonExpanded {
                isCloseButtonExpanded = false
            }
        } else if delta < -Style.directionThreshold {
            // 위로 스크롤 → 확장
            if !isCloseButtonExpanded {
                isCloseButtonExpanded = true
            }
        }

        Log.trace("handleScroll newOffset=\(newOffset) delta=\(delta) expanded \(prevExpanded)→\(isCloseButtonExpanded)", category: .view, level: .debug)
        lastScrollOffset = newOffset
    }

    private enum Style {
        // 닫기 버튼 — 확장 상태(텍스트 + 아이콘)
        static let expandedLeading: CGFloat = 22
        static let textToIconSpacing: CGFloat = 4
        static let expandedTrailing: CGFloat = 18
        static let expandedVerticalPadding: CGFloat = 16
        // 확장 상태 전체 높이 = verticalPadding(16) * 2 + iconSize(24) = 56
        // WebView 하단 contentInset 계산에 사용.
        static let expandedHeight: CGFloat = 56

        // 닫기 버튼 — 축소 상태(아이콘만, 44x44 고정)
        static let collapsedSize: CGFloat = 44

        // 닫기 버튼 corner radius
        static let expandedCornerRadius: CGFloat = 15
        static let collapsedCornerRadius: CGFloat = 10

        // x 아이콘
        static let iconSize: CGFloat = 24       // 아이콘 프레임 크기
        static let iconGlyphSize: CGFloat = 18  // SF Symbol 글리프 크기 (프레임 안에서 시각적 비율)

        // 화면 하단 safe area로부터 버튼까지의 여백
        static let bottomPadding: CGFloat = 24

        // 스크롤 → 버튼 상태 전환 임계값
        static let topThreshold: CGFloat = 2
        static let directionThreshold: CGFloat = 4

        // 애니메이션
        static let animationDuration: Double = 0.25
        // didFinish 이후 JS 렌더링이 안정화되기까지 기다리는 시간
        static let loadGracePeriod: Double = 0.3

        // 그림자
        static let shadowColor: Color = Color.black.opacity(0.16)
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 2
    }
}

// MARK: - WKWebView Wrapper

private struct TermsWKWebView: UIViewRepresentable {
    let url: URL
    let topContentInset: CGFloat
    let bottomContentInset: CGFloat
    let onScroll: (CGFloat) -> Void
    let onLoadFinish: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        // 시스템 자동 인셋을 끄고, SwiftUI에서 계산한 값을 직접 주입한다.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        // 로드 완료 전까지 스크롤을 차단. WKWebView 내부가 isScrollEnabled을
        // 토글할 수 있으므로 pan/pinch gesture를 직접 비활성화한다.
        Self.setScrollBlocked(true, on: webView.scrollView)
        Log.trace("makeUIView — panEnabled=\(webView.scrollView.panGestureRecognizer.isEnabled), contentSize=\(webView.scrollView.contentSize), inset=\(webView.scrollView.contentInset)", category: .view, level: .debug)
        applyInsets(to: webView)
        // WKWebView의 scrollView.delegate 슬롯은 내부적으로 점유되므로
        // KVO로 contentOffset 변경을 관찰한다.
        context.coordinator.observe(scrollView: webView.scrollView)
        // 최초 1회만 로드. 이후 updateUIView가 호출되어도 같은 url이면 재로드하지 않는다.
        context.coordinator.loadedURL = url
        webView.load(URLRequest(url: url))
        return webView
    }

    fileprivate static func setScrollBlocked(_ blocked: Bool, on scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.isEnabled = !blocked
        scrollView.pinchGestureRecognizer?.isEnabled = !blocked
        // isScrollEnabled도 함께 토글 (단, 이 값은 WKWebView 내부가 재설정할 수 있음)
        scrollView.isScrollEnabled = !blocked
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onScroll = onScroll
        context.coordinator.onLoadFinish = onLoadFinish
        applyInsets(to: uiView)
        // SwiftUI body re-render마다 호출되므로, 이미 로드한 url이면 절대 재로드 금지.
        // (서버 redirect로 trailing slash가 붙는 등의 차이로 무한 리로드가 발생하던 문제 방어)
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        uiView.load(URLRequest(url: url))
    }

    private func applyInsets(to webView: WKWebView) {
        let insets = UIEdgeInsets(
            top: topContentInset,
            left: 0,
            bottom: bottomContentInset,
            right: 0
        )
        if webView.scrollView.contentInset != insets {
            webView.scrollView.contentInset = insets
            webView.scrollView.verticalScrollIndicatorInsets = insets
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onLoadFinish: onLoadFinish)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onScroll: (CGFloat) -> Void
        var onLoadFinish: () -> Void
        // 이미 load() 호출한 URL — updateUIView에서 중복 로드를 막기 위한 가드.
        var loadedURL: URL?
        private var offsetObservation: NSKeyValueObservation?
        private var enabledObservation: NSKeyValueObservation?
        private var didLoad = false

        init(onScroll: @escaping (CGFloat) -> Void, onLoadFinish: @escaping () -> Void) {
            self.onScroll = onScroll
            self.onLoadFinish = onLoadFinish
        }

        func observe(scrollView: UIScrollView) {
            offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                guard let self else { return }
                Log.trace("KVO contentOffset.y=\(scrollView.contentOffset.y) isScrollEnabled=\(scrollView.isScrollEnabled) tracking=\(scrollView.isTracking) dragging=\(scrollView.isDragging) decelerating=\(scrollView.isDecelerating) contentSize=\(scrollView.contentSize)", category: .view, level: .debug)
                // 사용자의 드래그/관성 스크롤만 반응 (프로그래매틱 offset 변경은 무시)
                guard scrollView.isTracking || scrollView.isDecelerating else {
                    Log.trace("KVO — skip (programmatic offset)", category: .view, level: .debug)
                    return
                }
                let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                Log.trace("KVO → onScroll(\(offset))", category: .view, level: .debug)
                self.onScroll(offset)
            }
            // 진단용: isScrollEnabled 변경을 관찰. WKWebView 내부 토글은
            // KVO를 발화하지 않으므로 강제 복구는 불가능 (panGesture로 차단).
            enabledObservation = scrollView.observe(\.isScrollEnabled, options: [.new, .old]) { [weak self] _, change in
                guard self != nil else { return }
                let oldValue = change.oldValue ?? false
                let newValue = change.newValue ?? false
                Log.trace("KVO isScrollEnabled \(oldValue)→\(newValue)", category: .view, level: .debug)
            }
        }

        // MARK: WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 네비게이션 시작 시점에도 한 번 더 스크롤을 차단한다.
            TermsWKWebView.setScrollBlocked(true, on: webView.scrollView)
            Log.trace("didStartProvisionalNavigation — panEnabled=\(webView.scrollView.panGestureRecognizer.isEnabled)", category: .view, level: .debug)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            Log.trace("didCommit — isScrollEnabled=\(webView.scrollView.isScrollEnabled) contentSize=\(webView.scrollView.contentSize)", category: .view, level: .debug)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Log.trace("didFinish — pre enable contentSize=\(webView.scrollView.contentSize) offset=\(webView.scrollView.contentOffset.y) inset.top=\(webView.scrollView.contentInset.top)", category: .view, level: .debug)
            enableScrollAtTop(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Log.trace("didFail — error=\(error.localizedDescription)", category: .view, level: .error)
            enableScrollAtTop(webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Log.trace("didFailProvisionalNavigation — error=\(error.localizedDescription)", category: .view, level: .error)
            enableScrollAtTop(webView)
        }

        private func enableScrollAtTop(_ webView: WKWebView) {
            let scrollView = webView.scrollView
            // 안전망: 혹시 어긋난 offset이 있더라도 최상단에서 시작하도록 보정.
            scrollView.setContentOffset(
                CGPoint(x: 0, y: -scrollView.contentInset.top),
                animated: false
            )
            didLoad = true
            TermsWKWebView.setScrollBlocked(false, on: scrollView)
            Log.trace("enableScrollAtTop — panEnabled=\(scrollView.panGestureRecognizer.isEnabled) isScrollEnabled=\(scrollView.isScrollEnabled) offset=\(scrollView.contentOffset.y) didLoad=\(didLoad)", category: .view, level: .debug)
            // SwiftUI에 로드 완료 통보 — 로딩 인디케이터 해제용
            onLoadFinish()
        }
    }
}

// MARK: - Preview

#Preview("Terms WebView") {
    TermsWebViewView(
        store: Store(
            initialState: TermsWebViewFeature.State(
                url: URL(string: "https://www.apple.com/legal/internet-services/terms/site.html")!
            )
        ) {
            TermsWebViewFeature()
        }
    )
}
