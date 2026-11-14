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
import SafariServices
import DesignSystem
import CoreKit

struct BridgeWebView: UIViewRepresentable {
    /// 웹 문서 요청 제한 시간(#303). 기본값 60초는 서버 · 터널이 멈췄을 때 빈 화면 · 스피너가 너무 오래 이어진다.
    /// 전체 소요 시간이 아니라 데이터가 오지 않는 간격 기준이다 — 첫 응답 전이든 받는 도중이든 이만큼 아무것도 오지
    /// 않으면 실패(오류 화면 · 다시 시도)로 간다. 당겨서 새로고침(reload)도 처음 요청의 값을 이어받는다.
    static let documentRequestTimeout: TimeInterval = 20

    // 이 웹뷰가 리스트인지 상세 서브뷰인지. 브릿지 로그에 찍혀 "어느 웹뷰의 트래픽인지"를 구분한다.
    let source: WebBridgeSource
    let url: URL
    // 같은 URL로 강제 reload를 트리거하기 위한 토큰.
    let loadToken: UUID
    // 값이 바뀌면 웹뷰를 맨 위로 부드럽게 올린다. 메인 피드는 문서가 스크롤돼 웹을 고치지 않아도 된다.
    var scrollToTopToken: UUID?
    // 현재 백엔드 access token. 웹뷰 로드 전에 FE 세션 쿠키(oss_session)로 주입해
    // SSR이 첫 요청부터 인증되게 한다(특히 서브뷰). 게스트면 nil → 주입하지 않는다.
    var accessToken: String?
    // 네이티브 → 웹으로 전달 대기 중인 브릿지 메시지.
    let outbox: [WebBridgeOutboundEnvelope]
    // 좌우 스와이프 백/포워드 제스처 허용 여부. 상세 서브뷰는 웹 자체 헤더로 뒤로가기를
    // 처리하므로 false로 두어 제스처 충돌을 피한다.
    var allowsBackForwardNavigationGestures: Bool = true
    // 풀다운 리프레시 사용 여부. 글쓰기·수정처럼 다시 불러오면 쓰던 내용이 날아가는 화면은 끈다.
    var enablesPullToRefresh: Bool = true
    // 고정 셸(h-dvh + overflow:hidden) 화면에서, 키보드가 메인 문서를 위로 스크롤해 헤더가
    // 화면 밖으로 밀리는 것을 막기 위해 메인 스크롤뷰 세로 오프셋을 0으로 고정한다.
    var locksDocumentScroll: Bool = false
    // 오버스크롤(바운스) 영역에 드러나는 색. 웹 콘텐츠 배경과 어긋나면 바운스할 때 이음새가
    // 보이므로 화면별로 주입한다. 리스트 피드는 B&W/White, 상세 서브뷰는 True-White.
    var overscrollBackground: Color = Color.primitive.bw.trueWhite
    // 맨 위에서 당길 때 드러나는 풀다운 밴드의 바탕색. nil이면 기본 연파랑. 대회 목록만 머리줄 색과 맞추려고 넘긴다.
    var pullToRefreshBackground: Color?
    // 당겨서 새로고침 꾸밈(손 색·문구). 대회 목록만 .competition.
    var pullToRefreshStyle: WebPullToRefreshStyle = .feed
    // 탭 첫 화면 웹(홈 피드·대회 목록)만 켠다(#267). 웹뷰를 떠 있는 탭 바 밑까지 그리고, 탭 바가 가린 만큼을
    // 웹에 알려 맨 아래 글·고정 버튼이 탭 바 위에서 멈추게 한다. 키보드가 뜨면 가린 영역이 없으므로 0으로 돌린다.
    var extendsUnderTabBar: Bool = false
    // 이 웹뷰를 소유한 Feature가 실제로 처리하는 '사전 확인형' 메시지. 처리하지 않는 웹뷰가 지원한다고
    // 알리면 웹이 요청을 보내 놓고 응답 없이 기다리므로, 처리하는 화면만 넘긴다.
    var capabilities: [WebBridgeCapability] = []
    // 웹에 실제로 알리는 목록. 탭 바 밑까지 그리는 웹은 시트 열림을 이 웹뷰가 직접 처리하므로 덧붙인다(#314).
    private var injectedCapabilities: [WebBridgeCapability] {
        extendsUnderTabBar ? capabilities + [.setSheetOpen] : capabilities
    }
    // 진입 시간 측정의 시작 시각·경로(#298). 위에 쌓이는 상세만 넘기고, nil이면 재지 않는다.
    var entryOrigin: WebEntryTrace.Origin?
    // false가 되면 로딩을 멈추고 이후 콜백을 보내지 않는다. 화면을 닫는 도중(상태는 이미 지워졌는데
    // 웹뷰는 닫힘 애니메이션 동안 살아 있음) 늦게 온 로딩 완료가 없어진 화면으로 가지 않게 한다(#152).
    var isActive: Bool = true
    let onLoadingStarted: () -> Void
    let onLoadingFinished: () -> Void
    let onLoadingFailed: () -> Void
    // 웹 → 네이티브 인바운드 메시지(AppBridge) 수신 콜백.
    let onBridgeMessage: (WebBridgeInboundMessage) -> Void
    // 아웃바운드 메시지를 evaluateJavaScript로 실제 전달한 뒤 호출.
    let onOutboundDelivered: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            source: source,
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed,
            onBridgeMessage: onBridgeMessage,
            onOutboundDelivered: onOutboundDelivered
        )
    }

    /// 브릿지를 등록한 웹뷰를 만든다. 스플래시가 홈 피드를 미리 불러 둘 때(HomeFeedPreloader, #270)도
    /// 홈 웹뷰와 같은 웹뷰가 되도록 설정을 한곳에 둔다.
    static func makeWebView(capabilities: [WebBridgeCapability], messageHandler: WKScriptMessageHandler) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // 리스트·상세 웹뷰가 로그인 세션 쿠키(httpOnly 포함)를 공유하도록 영구 default 데이터스토어를 강제한다.
        config.websiteDataStore = .default()

        // 웹 → 네이티브 단일 라우터(AppBridge) 등록.
        // WKUserContentController가 핸들러를 strong 참조하므로 약한 프록시를 끼워 누수를 막는다.
        let contentController = WKUserContentController()
        contentController.add(
            WebBridgeScriptMessageProxy(delegate: messageHandler),
            name: WebBridge.appBridgeHandlerName
        )
        // 웹이 첫 사용자 탭 전에 지원 여부를 읽을 수 있도록 페이지 스크립트보다 먼저 주입한다.
        if !capabilities.isEmpty, let source = WebBridgeCapability.injectionScriptSource(for: capabilities) {
            contentController.addUserScript(
                WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        config.userContentController = contentController

        // 시스템 기본 입력 액세서리 바(위/아래/완료 회색 바)를 제거한다. 웹이 자체 하단 툴바
        // (사진/태그)를 키보드 위에 띄우므로 시스템 바는 불필요하고, 없는 편이 깔끔하다.
        return ChromelessWebView(frame: .zero, configuration: config)
    }

    // 웹뷰를 컨테이너 UIView로 감싼다. 직접 WKWebView를 반환하지 않는 이유는
    // 하단을 컨테이너의 keyboardLayoutGuide에 고정해 키보드만큼 높이를 줄이기 위해서다.
    // (아래 makeUIView 주석 참고)
    func makeUIView(context: Context) -> UIView {
        // 스플래시 동안 미리 불러 둔 홈 피드가 있으면 새로 만들지 않고 이어받는다(#270).
        let preload: HomeFeedPreload? = if case .list = source {
            HomeFeedPreloader.take(url: url, capabilities: injectedCapabilities)
        } else {
            nil
        }
        let webView = preload?.webView ?? Self.makeWebView(capabilities: injectedCapabilities, messageHandler: context.coordinator)
        if let entryOrigin {
            WebEntryTrace.begin(token: loadToken, origin: entryOrigin, url: url)
            WebEntryTrace.mark(.webView, token: loadToken)
        }
        // 이어받는 웹뷰는 받아 둔 이벤트를 다 넘긴 뒤에 대리자를 바꾼다(HomeFeedPreload.handOff).
        if preload == nil {
            webView.navigationDelegate = context.coordinator
        }
        // 새 창 링크(target=_blank, window.open)와 JS alert/confirm/prompt는 uiDelegate가 없으면 무반응이다(#63).
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // 오버스크롤/바운스 영역에 WKWebView 기본 회색이 비치지 않도록 웹 콘텐츠 배경과
        // 동일한 불투명 색으로 맞춘다.
        webView.isOpaque = true
        webView.backgroundColor = UIColor(overscrollBackground)
        webView.scrollView.backgroundColor = UIColor(overscrollBackground)

        #if DEBUG || BETA
        // Safari > 개발자용 메뉴에서 이 웹뷰를 인스펙트할 수 있게 허용한다. (DEBUG/BETA 빌드)
        webView.isInspectable = true
        #endif

        context.coordinator.attach(webView: webView)
        context.coordinator.entryTraceToken = entryOrigin == nil ? nil : loadToken
        // 고정 셸(상세): 키보드가 문서를 위로 스크롤해 헤더가 화면 밖으로 밀리는 것을 막는다.
        if locksDocumentScroll {
            context.coordinator.enableDocumentScrollLock(on: webView.scrollView)
        }

        // 풀다운 리프레시: 페이지를 가리는 전면 로딩 오버레이 대신, 디자인 밴드(연파랑 + 새로고침
        // 안내 → 완료 안내)를 오버스크롤 영역에 노출한다. (커스텀 컨트롤러가 contentInset으로 제어)
        if enablesPullToRefresh {
            context.coordinator.setupPullToRefresh(on: webView.scrollView, style: pullToRefreshStyle)
        }

        // 키보드가 뜨면 웹뷰 프레임 자체를 키보드 높이만큼 줄여(웹뷰를 키보드 위로 리사이즈)
        // layout/visual viewport를 축소한다. 그래야 웹(고정 셸 + 100dvh)의 입력바가 키보드 위에
        // 붙고, env(safe-area-inset-bottom)이 0이 되어 하단 여백/회색이 사라지며, 헤더는 고정되고
        // 본문만 스크롤된다. WKWebView는 viewport `interactive-widget=resizes-content` 지원이
        // 불안정해 레이아웃 뷰포트가 안 줄어들므로, 네이티브 프레임 리사이즈로 키보드를 처리한다.
        let container = KeyboardAvoidingWebContainer()
        container.reportsTabBarAsObscured = extendsUnderTabBar
        container.tabBarObscuredBottom = context.environment.tabBarReservedHeight
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        container.pinWebView(webView)

        let coordinator = context.coordinator
        if let preload {
            // 이미 같은 주소를 불러 두었으니 다시 불러오지 않는다. 토큰이 그사이 갱신됐으면
            // updateUIView가 쿠키를 맞추고, WEBVIEW_READY 때 새 토큰을 웹에 넘긴다.
            coordinator.markLoaded(url: url, token: loadToken)
            preload.handOff(to: coordinator)
        } else {
            // FE 세션 쿠키를 먼저 심고 나서 로드해, SSR 첫 네비게이션부터 인증되게 한다.
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            let token = accessToken
            Task { @MainActor in
                await WebSessionCookie.sync(accessToken: token, for: url, into: cookieStore)
                coordinator.load(url: url, token: loadToken)
            }
        }
        // 실제 웹뷰가 생겼으니 스플래시에서 미리 띄운 빈 웹뷰는 더 붙잡을 이유가 없다
        HomeFeedPreloader.releaseWarmWebView()
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        // 탭 바 높이는 안 보이는 동안(회전 등)에도 최신으로 둔다 — 다시 보일 때 옛 값이 한 번 쓰이지 않게.
        (container as? KeyboardAvoidingWebContainer)?.tabBarObscuredBottom = context.environment.tabBarReservedHeight
        guard isActive else {
            context.coordinator.deactivate()
            return
        }
        context.coordinator.update(
            onLoadingStarted: onLoadingStarted,
            onLoadingFinished: onLoadingFinished,
            onLoadingFailed: onLoadingFailed,
            onBridgeMessage: onBridgeMessage,
            onOutboundDelivered: onOutboundDelivered
        )
        context.coordinator.scrollToTop(token: scrollToTopToken)
        context.coordinator.setPullToRefreshBackground(pullToRefreshBackground.map { UIColor($0) })
        // 탭 첫 화면 웹만 스크롤을 AppTabView에 알린다 — 탭 바 숨김·맨 위로 버튼(#267).
        let tabRootScroll: TabRootScrollAction? = extendsUnderTabBar ? context.environment.tabRootScroll : nil
        let keyboardAvoidingContainer = container as? KeyboardAvoidingWebContainer
        keyboardAvoidingContainer?.onScroll = tabRootScroll?.report
        // 웹 시트가 열린 동안 가린 높이를 0으로 돌리고 탭 바를 숨긴다(#314).
        context.coordinator.onSheetOpenChanged = extendsUnderTabBar
            ? { [weak keyboardAvoidingContainer] isOpen in
                keyboardAvoidingContainer?.isSheetOpen = isOpen
                tabRootScroll?.reportSheetOpen(isOpen)
            }
            : nil
        // 토큰 변동(갱신) 시에도 세션 쿠키를 최신으로 유지한 뒤 (재)로드/플러시한다.
        let cookieStore = context.coordinator.webView?.configuration.websiteDataStore.httpCookieStore
            ?? WKWebsiteDataStore.default().httpCookieStore
        let coordinator = context.coordinator
        let token = accessToken
        Task { @MainActor in
            await WebSessionCookie.sync(accessToken: token, for: url, into: cookieStore)
            coordinator.load(url: url, token: loadToken)
            coordinator.flushOutbox(outbox)
        }
    }

    static func dismantleUIView(_ container: UIView, coordinator: Coordinator) {
        // 진행 중인 로딩의 콜백이 해제 뒤에 오지 않게 멈춘다(스와이프로 닫으면 isActive를 거치지 않는다).
        coordinator.deactivate()
        // 핸들러를 정리해 WKUserContentController가 잔존 참조를 들고 있지 않도록 한다.
        coordinator.webView?.configuration.userContentController
            .removeScriptMessageHandler(forName: WebBridge.appBridgeHandlerName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
        private let source: WebBridgeSource
        private var onLoadingStarted: () -> Void
        private var onLoadingFinished: () -> Void
        private var onLoadingFailed: () -> Void
        private var onBridgeMessage: (WebBridgeInboundMessage) -> Void
        private var onOutboundDelivered: (UUID) -> Void

        private var lastLoadedURL: URL?
        private var lastLoadToken: UUID?
        private var lastScrollToTopToken: UUID?
        // 이미 evaluateJavaScript로 전달한 아웃바운드 id. updateUIView가 여러 번
        // 호출돼도 같은 메시지를 중복 주입하지 않도록 가드한다.
        private var deliveredOutboundIDs: Set<UUID> = []

        // 로드·아웃바운드 주입·리프레시 등에서 공용으로 쓰는 webView 약한 참조.
        // (컨테이너로 감싸 makeUIView가 webView를 직접 반환하지 않으므로 직접 보관한다.)
        private(set) weak var webView: WKWebView?
        // 커스텀 풀다운 리프레시 컨트롤러. enablesPullToRefresh인 웹뷰에서만 생성된다.
        private var pullToRefresh: WebPullToRefreshController?
        // 현재 로드가 풀다운 리프레시로 시작됐는지. true면 전면 로딩 오버레이를
        // 띄우지 않고 리프레시 밴드만 유지한다.
        private var isRefreshing = false
        // 당겨서 새로고침이 부른 reload의 navigation. 그 전에 진행 중이던 로드의 완료·실패 알림이
        // 새로고침을 끝낸 것으로 잘못 읽히지 않게, 이 navigation의 결과로만 새로고침을 끝낸다(#432).
        private var refreshNavigation: WKNavigation?
        // 고정 셸(상세) 웹뷰에서 키보드가 메인 문서를 위로 스크롤해 헤더가 화면 밖으로 밀리는 것을
        // 막기 위해, 메인 스크롤뷰의 세로 오프셋을 0으로 고정할지 여부.
        private var locksDocumentScroll = false
        // deactivate() 이후에는 웹뷰가 아직 살아 있어도 store로 아무것도 보내지 않는다.
        private var isDeactivated = false
        // 웹 시트 열림·닫힘을 받는 곳(#314). 탭 바 밑까지 그리는 웹뷰만 updateUIView가 넣는다.
        var onSheetOpenChanged: (@MainActor (Bool) -> Void)?
        // 웹이 마지막으로 알린 시트 열림. 시트를 연 채 문서가 바뀌면(새로고침·이동) 닫힘을 못 받으니 직접 푼다.
        private var isWebSheetOpen = false
        // 진입 시간 측정의 키(#298). 웹뷰를 만들 때의 loadToken — 다시 시도로 토큰이 바뀌어도 첫 진입 기록을 끝맺는다.
        var entryTraceToken: UUID?

        init(
            source: WebBridgeSource,
            onLoadingStarted: @escaping () -> Void,
            onLoadingFinished: @escaping () -> Void,
            onLoadingFailed: @escaping () -> Void,
            onBridgeMessage: @escaping (WebBridgeInboundMessage) -> Void,
            onOutboundDelivered: @escaping (UUID) -> Void
        ) {
            self.source = source
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

        /// 화면이 닫히는 중이거나 해제될 때 — 로딩을 멈추고 이후 콜백을 끊는다. 여러 번 불려도 된다.
        func deactivate() {
            guard !isDeactivated else { return }
            // 시트를 연 채 멈추면 닫힘 신호가 오지 않는다 — 탭 바가 숨은 채 남지 않게 먼저 푼다(#314).
            setWebSheetOpen(false)
            isDeactivated = true
            if let entryTraceToken { WebEntryTrace.end(.closed, token: entryTraceToken) }
            webView?.stopLoading()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
        }

        func scrollToTop(token: UUID?) {
            guard token != lastScrollToTopToken else { return }
            lastScrollToTopToken = token
            guard let scrollView = webView?.scrollView else { return }
            scrollView.setContentOffset(
                CGPoint(x: 0, y: -scrollView.adjustedContentInset.top),
                animated: true
            )
        }

        func load(url: URL, token: UUID) {
            guard !isDeactivated, let webView else { return }
            // URL이 바뀌었거나 retry 토큰이 갱신된 경우에만 reload.
            guard lastLoadedURL != url || lastLoadToken != token else { return }
            lastLoadedURL = url
            lastLoadToken = token
            // 재로드(재시도) 시 웹 컨텍스트가 초기화되므로 전달 기록도 비운다.
            // 재로드 후 다시 WEBVIEW_READY가 오면 초기 동기화가 새로 일어난다.
            deliveredOutboundIDs.removeAll()
            WebEntryTrace.mark(.load, token: token)
            webView.load(URLRequest(url: url, timeoutInterval: BridgeWebView.documentRequestTimeout))
        }

        // 로드·아웃바운드·키보드 처리에 쓸 webView를 보관한다.
        func attach(webView: WKWebView) {
            self.webView = webView
        }

        /// 미리 불러 둔 웹뷰를 이어받았을 때 — 같은 주소·토큰으로 다시 불러오지 않게 표시해 둔다(#270).
        func markLoaded(url: URL, token: UUID) {
            lastLoadedURL = url
            lastLoadToken = token
        }

        // 고정 셸 화면에서 메인 문서 스크롤을 0에 고정한다. 키보드가 포커스된 입력칸을 보이려
        // 문서를 위로 스크롤(contentOffset.y>0)해 헤더가 화면 밖으로 밀리는 것을 되돌려 막는다.
        // (웹은 overflow:hidden이라 메인 문서는 스크롤될 일이 없고, 본문은 별도 스크롤러로 스크롤된다.)
        // 위로 당기는 쪽(y<0)은 당겨서 새로고침이 붙은 화면에서만 풀어 두되, 키보드가 떠 있으면
        // 쓰던 댓글이 새로고침에 날아가지 않게 그쪽도 막는다(#432).
        func enableDocumentScrollLock(on scrollView: UIScrollView) {
            locksDocumentScroll = true
            scrollView.delegate = self
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if locksDocumentScroll, isDocumentScrollBlocked(scrollView) {
                scrollView.contentOffset.y = 0
                return
            }
            pullToRefresh?.scrollViewDidScroll(scrollView)
        }

        private func isDocumentScrollBlocked(_ scrollView: UIScrollView) -> Bool {
            let offsetY = scrollView.contentOffset.y
            if offsetY > 0 { return true }
            guard offsetY < 0 else { return false }
            // 당겨서 새로고침이 없는 화면(글쓰기·수정)은 예전처럼 위로도 0에 묶는다.
            guard let pullToRefresh else { return true }
            // 띠가 inset을 쥐고 있는 동안(새로고침 중·접히는 중)엔 키보드가 올라와도 되돌리지 않는다 — 화면이 튄다.
            if isRefreshing || pullToRefresh.holdsInset { return false }
            return (webView?.superview as? KeyboardAvoidingWebContainer)?.isKeyboardVisible ?? false
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            pullToRefresh?.scrollViewDidEndDragging(scrollView)
        }

        // 커스텀 풀다운 리프레시를 스크롤뷰에 부착한다.
        func setupPullToRefresh(on scrollView: UIScrollView, style: WebPullToRefreshStyle) {
            scrollView.delegate = self
            pullToRefresh = WebPullToRefreshController(scrollView: scrollView, style: style) { [weak self] in
                self?.beginRefresh()
            }
        }

        func setPullToRefreshBackground(_ color: UIColor?) {
            pullToRefresh?.setBandBackground(color)
        }

        private func beginRefresh() {
            guard let webView else { return }
            isRefreshing = true
            // 리프레시로 웹 컨텍스트가 재초기화되므로 전달 기록을 비워
            // 재로드 후 WEBVIEW_READY 핸드셰이크에서 상태가 다시 동기화되게 한다.
            deliveredOutboundIDs.removeAll()
            refreshNavigation = nil
            guard locksDocumentScroll else {
                reloadForRefresh(webView)
                return
            }
            // 고정 셸(상세)은 띠가 로딩 높이로 내려앉는 걸 웹이 본 뒤에 다시 불러온다. 곧바로 부르면
            // 웹이 손 뗀 순간의 당김 값에서 멈춰, 띠와 화면 사이에 빈 틈이 벌어진다(#432).
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(WebPullToRefreshController.settleDuration))
                guard let self, !self.isDeactivated, self.isRefreshing, let webView = self.webView else { return }
                self.reloadForRefresh(webView)
            }
        }

        private func reloadForRefresh(_ webView: WKWebView) {
            // 첫 로드를 끊고 다시 불러오면 그 뒤 값은 첫 진입 시간이 아니다(#298).
            if let entryTraceToken { WebEntryTrace.end(.refreshed, token: entryTraceToken) }
            refreshNavigation = webView.reload()
            // 다시 불러올 페이지가 없으면 기다릴 결과도 없으니 띠를 바로 닫는다.
            guard refreshNavigation == nil else { return }
            isRefreshing = false
            pullToRefresh?.finishRefreshing(success: false)
        }

        /// 새로고침이 부른 reload의 결과일 때만 띠를 닫는다. reload를 아직 부르지 않았거나 다른 로드의
        /// 알림이면 무시한다. `navigation`이 nil이면 navigation 구분 없이 reload 뒤의 실패로 본다.
        private func endRefreshing(success: Bool, navigation: WKNavigation?) {
            guard isRefreshing, let refreshNavigation else { return }
            if let navigation, navigation !== refreshNavigation { return }
            isRefreshing = false
            self.refreshNavigation = nil
            pullToRefresh?.finishRefreshing(success: success)
        }

        // 대기열의 아웃바운드 메시지를 순서대로 웹에 주입한다.
        func flushOutbox(_ outbox: [WebBridgeOutboundEnvelope]) {
            guard !isDeactivated, let webView else { return }
            for envelope in outbox where !deliveredOutboundIDs.contains(envelope.id) {
                guard let script = envelope.message.makeJavaScript() else {
                    // 직렬화 실패한 메시지는 영구히 막히지 않도록 전달 처리해 대기열에서 제거한다.
                    deliveredOutboundIDs.insert(envelope.id)
                    onOutboundDelivered(envelope.id)
                    continue
                }
                deliveredOutboundIDs.insert(envelope.id)
                WebBridge.logOutbound(envelope.message, source: source)
                webView.evaluateJavaScript(script) { [weak self] _, error in
                    guard let self, !self.isDeactivated else { return }
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
            receiveBridgeMessage(message.body)
        }

        /// 웹이 보낸 브릿지 메시지를 처리한다. 미리 불러 둔 홈 피드가 받아 둔 메시지도 이리로 넘긴다(#270).
        func receiveBridgeMessage(_ body: Any) {
            guard !isDeactivated else { return }
            // 해석 결과와 별개로, 웹이 보낸 원본을 먼저 남긴다(파싱 실패·계약 위반도 추적 가능하도록).
            WebBridge.logInboundRaw(body, source: source)
            guard let inbound = WebBridgeInboundMessage.decode(from: body) else { return }
            WebBridge.logInbound(inbound, source: source)
            if case let .setSheetOpen(isOpen) = inbound {
                setWebSheetOpen(isOpen)
                return
            }
            if let entryTraceToken {
                switch inbound {
                case .webViewReady: WebEntryTrace.mark(.ready, token: entryTraceToken)
                case .pageReady: WebEntryTrace.mark(.page, token: entryTraceToken)
                default: break
                }
            }
            onBridgeMessage(inbound)
        }

        private func setWebSheetOpen(_ isOpen: Bool) {
            // 받을 곳이 아직 없으면(미리 불러 둔 홈 피드를 넘겨받는 중 등) 기록하지 않는다 — 적용 안 된 열림이 남아
            // 다음 열림을 같은 값이라며 버리지 않게.
            guard let onSheetOpenChanged, isWebSheetOpen != isOpen else { return }
            isWebSheetOpen = isOpen
            onSheetOpenChanged(isOpen)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            // 웹 프로세스가 죽으면 닫힘 신호도 새 문서(didCommit)도 오지 않을 수 있다 — 시트가 열린 채였으면 탭 바를 돌려놓는다.
            setWebSheetOpen(false)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 풀다운 리프레시 중에는 페이지를 가리는 전면 오버레이 대신 스피너만 유지한다.
            guard !isRefreshing else { return }
            onLoadingStarted()
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // 첫 응답이 와서 문서를 그리기 시작한 시점. 진입 시간 측정에만 쓴다(#298).
            if let entryTraceToken { WebEntryTrace.mark(.commit, token: entryTraceToken) }
            // 새 문서에는 시트가 없다 — 시트를 연 채 문서가 바뀌었으면 탭 바를 돌려놓는다.
            setWebSheetOpen(false)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let entryTraceToken { WebEntryTrace.mark(.finish, token: entryTraceToken) }
            endRefreshing(success: true, navigation: navigation)
            onLoadingFinished()
            // 웹이 로드되며 overscroll-behavior로 바운스를 끌 수 있어 풀다운 여지를 재확보한다.
            pullToRefresh?.enforceVerticalBounce()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Log.trace("Bridge webview didFail: \(error)", category: .network, level: .error)
            endRefreshing(success: false, navigation: navigation)
            guard !isCancelledByRefresh(error) else { return }
            if let entryTraceToken { WebEntryTrace.end(.failed, token: entryTraceToken) }
            onLoadingFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Log.trace("Bridge webview didFailProvisionalNavigation: \(error)", category: .network, level: .error)
            endRefreshing(success: false, navigation: navigation)
            guard !isCancelledByRefresh(error) else { return }
            if let entryTraceToken { WebEntryTrace.end(.failed, token: entryTraceToken) }
            onLoadingFailed()
        }

        /// 새로고침의 reload가 앞서 진행 중이던 로드를 취소한 알림인지. 그 로드는 실패가 아니라
        /// 새로고침에 자리를 내준 것이라 실패 화면을 띄우지 않는다.
        private func isCancelledByRefresh(_ error: Error) -> Bool {
            isRefreshing && (error as NSError).code == NSURLErrorCancelled
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
                endRefreshing(success: false, navigation: nil)
                onLoadingFailed()
                return
            }
            decisionHandler(.allow)
        }

        // MARK: WKUIDelegate

        // 새 창 요청. 커뮤니티 도메인이면 현재 웹뷰에서 이어 열고, 외부 도메인은 앱 위 브라우저로 띄운다(#316).
        // 새 WKWebView를 만들지 않으므로 nil을 반환한다.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            if url.host() == lastLoadedURL?.host() {
                webView.load(navigationAction.request)
            } else if url.scheme == "http" || url.scheme == "https" {
                openExternal(url, from: webView)
            } else {
                Log.trace("Bridge webview 새 창 요청 무시(지원하지 않는 scheme): \(url)", category: .view, level: .info)
            }
            return nil
        }

        // WebKit은 completionHandler가 정확히 한 번 호출되지 않으면 예외를 던지므로,
        // 띄울 화면이 없을 때도 기본값으로 즉시 완료한다.
        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler() })
            present(alert, from: webView, onFailure: completionHandler)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler(true) })
            present(alert, from: webView, onFailure: { completionHandler(false) })
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak alert] _ in
                completionHandler(alert?.textFields?.first?.text)
            })
            present(alert, from: webView, onFailure: { completionHandler(nil) })
        }

        /// 바깥 주소를 앱 위 브라우저(SFSafariViewController)로 띄운다(#316). 닫으면(완료·아래로 쓸기) 웹뷰 화면이 그대로 남는다.
        /// 다른 앱이 맡는 유니버설 링크는 지금처럼 그 앱으로 넘기고, 아닐 때만 앱 안에서 연다.
        private func openExternal(_ url: URL, from webView: WKWebView) {
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { [weak self, weak webView] openedInApp in
                guard !openedInApp, let self, let webView else { return }
                // 이미 브라우저가 떠 있으면(빠른 연타 등) 겹쳐 띄우지 않는다.
                guard !(self.topViewController(of: webView) is SFSafariViewController) else { return }
                let safari = SFSafariViewController(url: url)
                // 아래로 쓸어 닫을 수 있는 시트로 띄워, 뒤의 웹뷰 화면을 덮어 내리지 않는다.
                safari.modalPresentationStyle = .pageSheet
                self.present(safari, from: webView) {
                    UIApplication.shared.open(url)
                }
            }
        }

        /// 웹뷰가 속한 윈도우의 최상단 화면.
        private func topViewController(of webView: WKWebView) -> UIViewController? {
            var presenter = webView.window?.rootViewController
            while let presented = presenter?.presentedViewController {
                presenter = presented
            }
            return presenter
        }

        /// 웹뷰가 속한 윈도우의 최상단 화면에서 알럿·브라우저를 띄운다. (SwiftUI 시트·커버 위에서도 보이도록)
        private func present(_ viewController: UIViewController, from webView: WKWebView, onFailure: () -> Void) {
            guard let presenter = topViewController(of: webView) else {
                Log.trace("Bridge webview 화면을 띄울 곳이 없음", category: .view, level: .error)
                onFailure()
                return
            }
            presenter.present(viewController, animated: true)
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
    private weak var webView: WKWebView?
    private var offsetObservation: NSKeyValueObservation?
    // 켜면 떠 있는 탭 바 자리(tabBarObscuredBottom)를 웹뷰가 가려진 영역으로 알린다(#267).
    var reportsTabBarAsObscured = false
    // 화면 바닥에서 탭 바 윗변까지(AppTabView가 환경값으로 건넴, #284). 아래 안전 영역은 SwiftUI의
    // `.safeAreaInset`이 넘어오지 않아 기기 홈 막대 자리(34)뿐이라 쓰지 않는다. 탭 바가 숨어도 같은 값이라
    // 웹의 글쓰기 버튼·마지막 글이 탭 바와 함께 들썩이지 않는다(움직이는 건 탭 바 하나).
    var tabBarObscuredBottom: CGFloat = 0 {
        didSet { if reportsTabBarAsObscured, oldValue != tabBarObscuredBottom { setNeedsLayout() } }
    }
    // 웹 바텀 시트가 떠 있는지(#314). 떠 있으면 탭 바가 숨으므로 가린 영역이 없다 — 시트·딤이 화면 맨 아래까지 온다.
    var isSheetOpen = false {
        didSet { if reportsTabBarAsObscured, oldValue != isSheetOpen { setNeedsLayout() } }
    }
    // 스크롤할 때마다 부른다(탭 첫 화면 웹만, #267).
    var onScroll: (@MainActor (CGFloat, CGFloat, Bool) -> Void)?
    // 키보드가 떠 있는지. 고정 셸(상세)이 댓글을 쓰는 중에 당겨서 새로고침되지 않게 본다(#432).
    private(set) var isKeyboardVisible = false

    func pinWebView(_ webView: WKWebView) {
        self.webView = webView
        offsetObservation = webView.scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            MainActor.assumeIsolated { self?.reportScroll(of: scrollView) }
        }
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
        // 탭 첫 화면은 떠 있는 탭 바 자리만큼 아래 안전 영역이 커져 있어(#267), 기기 자체의 아래 안전 영역과 견준다.
        let deviceBottomInset = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
        let keyboardVisible = distanceFromBottom > deviceBottomInset + 8
        isKeyboardVisible = keyboardVisible
        if reportsTabBarAsObscured, let webView {
            let obscuredBottom = keyboardVisible || isSheetOpen ? 0 : tabBarObscuredBottom
            if webView.obscuredContentInsets.bottom != obscuredBottom {
                webView.obscuredContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: obscuredBottom, right: 0)
                webView.scrollView.verticalScrollIndicatorInsets.bottom = obscuredBottom
            }
        }
        let shouldPinBottom = !keyboardVisible
        guard bottomToBottomEdge?.isActive != shouldPinBottom else { return }
        bottomToBottomEdge?.isActive = shouldPinBottom
    }

    private func reportScroll(of scrollView: UIScrollView) {
        guard let onScroll else { return }
        let inset = scrollView.adjustedContentInset
        let offsetY = scrollView.contentOffset.y + inset.top
        let maxOffsetY = scrollView.contentSize.height + inset.top + inset.bottom - scrollView.bounds.height
        let isUserScrolling = scrollView.isTracking || scrollView.isDecelerating
        onScroll(offsetY, maxOffsetY, isUserScrolling)
    }
}

/// 시스템 기본 입력 액세서리 바(키보드 위 위/아래/완료 회색 폼 어시스턴트)를 제거한 WKWebView.
/// 웹이 자체 하단 툴바(사진/태그)를 키보드 위에 띄우므로 시스템 바는 불필요하고, 없는 편이 깔끔하다.
private final class ChromelessWebView: WKWebView {
    override var inputAccessoryView: UIView? { nil }
}
