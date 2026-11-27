//
//  CommunityView.swift
//  Presentation
//
//  커뮤니티 탭 컨테이너 — WKWebView를 호스팅하고 로딩/에러 오버레이를 그린다.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import CoreKit

public struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    // 웹 아래 시트의 딤이 깔려 있는지(SET_SHEET_OPEN의 dimmed) — 머리줄도 웹 딤과 같이 어둡게 덮는다.
    let isWebSheetDimmed: Bool
    @Environment(\.scenePhase) private var scenePhase
    // 웹이 머리줄 뒤까지 유리 면을 그리는 중인지(SET_TOP_GLASS). 그리는 동안 머리줄 바탕을 비워 웹 유리 면 한 장이 비치게 한다.
    @State private var webDrawsTopGlass = false

    public init(store: StoreOf<CommunityFeature>, isWebSheetDimmed: Bool = false) {
        self.store = store
        self.isWebSheetDimmed = isWebSheetDimmed
    }

    private enum Metrics {
        // 검색 버튼에서 사용(알림함 종은 NotificationInboxButton이 같은 값으로 그린다)
        static let trailingIconSize: CGFloat = 24
        static let trailingIconButtonSize: CGFloat = 40
        static let leadingInset: CGFloat = 16
        static let rowHeight: CGFloat = 44
        static let logoHeight: CGFloat = 20
        static let headerTintAnimation: Animation = .easeOut(duration: 0.2)
    }

    public var body: some View {
        // 웹을 머리줄 · 상태바 뒤까지 깔고 머리줄을 위에 얹는다 — 글을 내리면 머리줄 뒤로 지나가며 비친다.
        ZStack(alignment: .top) {
            ZStack {
                if let url = store.url {
                    BridgeWebView(
                        source: .list,
                        url: url,
                        loadToken: store.loadToken,
                        scrollToTopToken: store.scrollToTopToken,
                        accessToken: store.accessToken,
                        outbox: store.outbox,
                        // 리스트 피드 웹 배경과 맞춰, 바운스 때 다른 색이 드러나지 않게 한다.
                        // 맨 위 진한 띠가 보이는 동안은 띠 색 — 당겨 내려도 띠 위가 희게 비지 않게.
                        overscrollBackground: headerTint ?? Color.primitive.bw.white,
                        // 머리줄이 칠해져 있으면 당길 때 드러나는 밴드도 같은 색으로 잇고 손을 흰 손으로 바꾼다(대회 탭과 같음).
                        pullToRefreshBackground: headerTint,
                        pullToRefreshStyle: headerTint == nil ? .feed : .feedOnDark,
                        extendsUnderTabBar: true,
                        extendsUnderTabHeader: true,
                        onTopGlassChanged: { webDrawsTopGlass = $0 },
                        // 맨 위 띠 색을 받으려고 알린다(HOME_HEADER_TINT).
                        capabilities: CommunityFeature.listCapabilities,
                        onLoadingStarted: { store.send(.internal(.loadingStarted)) },
                        onLoadingFinished: { store.send(.internal(.loadingFinished)) },
                        onLoadingFailed: { store.send(.internal(.loadingFailed($0))) },
                        onScreenLoadMeasured: { store.send(.internal(.screenLoadMeasured($0))) },
                        onRefreshStarted: { store.send(.internal(.refreshStarted)) },
                        onBridgeMessage: { store.send(.internal(.bridgeMessageReceived($0))) },
                        onOutboundDelivered: { store.send(.internal(.outboundDelivered(id: $0))) }
                    )
                    // 피드가 떠 있는 탭 바 · 머리줄 뒤로 비쳐 흐르게 위아래 끝까지 그린다(#267).
                    .ignoresSafeArea(.container, edges: [.top, .bottom])
                }

                WebLoadingOverlay(isLoading: store.isLoading)
                    // 웹이 탭 바 · 머리줄 밑까지 그려지므로 덮개도 그만큼 덮어, 그 자리에 웹 바탕(흰색)이 따로 비치지 않게 한다.
                    .ignoresSafeArea(.container, edges: [.top, .bottom])

                if store.hasError {
                    errorOverlay
                        .padding(.top, Metrics.rowHeight)
                }
            }
            // SwiftUI 자동 키보드 회피를 끄고, 키보드 대응은 BridgeWebView의 keyboardLayoutGuide
            // 한 곳에서만 처리한다. 글쓰기 화면이 웹 내부 라우트로 열릴 때도 웹뷰 높이만 줄어
            // 웹의 sticky 하단 툴바가 키보드 위에 붙는다. (이중 보정·애니메이션 충돌 방지)
            .ignoresSafeArea(.keyboard, edges: .bottom)

            gnb
                // 머리줄 바탕이 비어 있으면 그 뒤를 웹 딤이 이미 덮으므로 글자 · 아이콘만 어둡게 한다(두 번 어두워지지 않게).
                .webSheetHeaderDim(isWebSheetDimmed, webDimsBehind: webDrawsTopGlass && headerTint == nil)
        }
        .background(Color.component.background.default)
        .onAppear { store.send(.view(.onAppear)) }
        .onWebScreenVisibilityChange { store.send(.view(.visibilityChanged($0))) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.view(.sceneBecameActive)) }
        }
        .modifier(DebugDomainAlert(store: store))
    }

    // 웹이 알린 맨 위 띠 색. nil이면 흰 머리줄.
    private var headerTint: Color? { store.headerTint.map { Color(hex: $0) } }

    private var gnb: some View {
        // 왼쪽에 OSS 로고, 오른쪽에 종 · 검색. 카테고리 칩은 웹 피드가 그린다.
        // 웹 맨 위 진한 띠가 보이는 동안은 머리줄도 그 색으로 칠해 띠와 한 면으로 잇고, 구분선을 뺀다.
        // 웹이 유리 면을 그리는 동안은 바탕을 비워 두어 웹 유리 면이 머리줄과 칩 줄을 한 장으로 덮게 한다(구분선도 뺀다).
        logoRow
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.component.navibar.container.divider)
                    .frame(height: 1)
                    .opacity(headerTint == nil && !webDrawsTopGlass ? 1 : 0)
            }
            // 바탕이 비어도 머리줄을 누르면 뒤로 지나가는 글이 눌리지 않게 막는다(비운 바탕도 거의 투명한 면으로 두어 손가락을 받는다).
            .contentShape(Rectangle())
            // 바탕을 상단 safe area(상태바)까지 끌어올려 회색(background.default)이 상태바에 번지지 않게 한다.
            .background {
                (headerTint ?? (webDrawsTopGlass ? Color.component.header.background.opacity(0.001) : Color.component.header.background))
                    .ignoresSafeArea(edges: .top)
            }
            // 띠가 들고 날 때 한 번에 바뀐다. 상태바 글자는 같은 순간 바로 바뀌므로, 바탕이 늦게 따라와
            // 먹색 위 검은 글자처럼 어긋나 보이지 않게 짧게 · 처음부터 빠르게 바꾼다(0.5초 easeInOut은 절반까지 0.27초 걸렸음).
            .animation(Metrics.headerTintAnimation, value: store.headerTint)
    }

    private var logoRow: some View {
        HStack(spacing: 0) {
            Assets.Splash.logo.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: Metrics.logoHeight)
                .foregroundStyle(headerTint == nil ? Color.component.header.text : Color.primitive.bw.white)
                .padding(.leading, Metrics.leadingInset)
                .accessibilityLabel("홈")
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                #if DEBUG || BETA
                Button {
                    store.send(.view(.debugChangeDomainTapped))
                } label: {
                    Image(systemName: "network")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                #endif

                if store.isNotificationButtonVisible {
                    NotificationInboxButton(
                        hasUnread: store.hasUnreadNotification,
                        iconColor: iconColor,
                        dotRingColor: headerTint ?? Color.primitive.bw.white
                    ) {
                        store.send(.view(.notificationTapped))
                    }
                }

                Button {
                    store.send(.view(.searchTapped))
                } label: {
                    Assets.Common.Icon.search.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metrics.trailingIconSize, height: Metrics.trailingIconSize)
                        .foregroundStyle(iconColor)
                        .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색")
            }
        }
        .padding(.trailing, 8)
        .frame(height: Metrics.rowHeight)
    }

    // 종 · 검색 색. 진한 띠 위에서는 흰색.
    private var iconColor: Color {
        headerTint == nil ? Color.component.header.iconButton : Color.primitive.bw.white
    }

    private var errorOverlay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 13) {
                Text(store.connectionRetry.errorTitle)
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

// MARK: - 테스트용 웹뷰 도메인 변경 Alert

/// IP/도메인을 입력받아 즉시 해당 주소의 웹뷰를 다시 로드하는 테스트용 입력 다이얼로그.
/// DEBUG/BETA 빌드에서만 트리거되며, 릴리즈에서는 진입 버튼이 노출되지 않는다.
private struct DebugDomainAlert: ViewModifier {
    let store: StoreOf<CommunityFeature>

    func body(content: Content) -> some View {
        content.alert(
            "웹뷰 도메인 변경 (테스트)",
            isPresented: Binding(
                get: { store.isDebugURLAlertPresented },
                set: { if !$0 { store.send(.view(.debugURLAlertDismissed)) } }
            )
        ) {
            // 플레이스홀더는 실제 기본값(Info.plist WEB_URL)과 일치시킨다.
            // 입력 필드를 지웠을 때 "비워두면 어디로 가는지"가 그대로 보여야 오해가 없다.
            TextField(
                CommunityFeature.defaultWebURLString,
                text: Binding(
                    get: { store.debugURLInput },
                    set: { store.send(.view(.debugURLInputChanged($0))) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)

            Button("적용") { store.send(.view(.debugURLApplyTapped)) }

            // AASA 배포 전에도 딥링크 파싱·라우팅을 확인하기 위한 통로.
            // 입력한 주소를 실제 유니버설 링크와 같은 경로로 태워 게시글 상세를 연다.
            Button("딥링크로 열기") { store.send(.view(.debugDeepLinkOpenTapped)) }

            // 운영/개발은 입력 없이 한 번에 전환한다. 값이 주입되지 않은 구성(Release)에서는
            // 버튼 자체를 만들지 않아 빈 주소로 로드되는 일이 없게 한다.
            ForEach(CommunityFeature.DebugServer.allCases, id: \.self) { server in
                if !server.urlString.isEmpty {
                    Button(server.title, role: server == .prod ? .destructive : nil) {
                        store.send(.view(.debugServerTapped(server)))
                    }
                }
            }

            Button("취소", role: .cancel) {}
        } message: {
            Text("불러올 웹뷰 주소를 입력하세요. 예) 192.168.0.10:3000\n스킴(http/https)을 생략하면 http로 처리되고, 비워두고 적용하면 기본값으로 복원됩니다.\n운영·개발 서버는 아래 버튼으로 바로 전환됩니다.\n[딥링크로 열기]는 입력한 전체 주소(https://…/community/123)를 유니버설 링크처럼 열어봅니다.")
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
