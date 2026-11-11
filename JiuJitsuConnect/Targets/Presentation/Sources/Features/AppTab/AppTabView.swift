//
//  AppTabView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

public struct AppTabView: View {
    @Bindable var store: StoreOf<AppTabFeature>

    public init(store: StoreOf<AppTabFeature>) {
        self.store = store
    }

    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var tabLens

    // 스크롤로 탭 바를 숨기고 맨 위로 버튼을 띄우는 상태(#267). 무신사처럼 내리면 숨고 올리면 아래에서 올라온다.
    @State private var isTabBarHidden = false
    // 맨 위에서 충분히 내려와 맨 위로 버튼을 띄울 탭들
    @State private var tabsAwayFromTop: Set<AppTabFeature.Tab> = []
    @State private var scrollTracker = TabScrollTracker()
    // 화면 맨 아래 안전 영역(홈 막대 자리)
    @State private var deviceBottomInset: CGFloat = 0
    // 맨 위로 동그라미가 어디로 들어가는지 — 탭 바가 올라오면 그 맨 위로 칸으로, 아니면 제자리에서 사라진다.
    // 나타날 땐 늘 화면 아래에서 올라온다.
    @State private var circleExit: CircleMotion = .inPlace

    private enum ScrollMetrics {
        // 이보다 위(맨 위 가까이)에선 늘 탭 바를 보인다.
        static let revealZone: CGFloat = 44
        // 이만큼 이상 같은 방향으로 움직여야 탭 바를 숨기거나 꺼낸다(손떨림 무시).
        static let directionThreshold: CGFloat = 8
        // 이보다 내려오면 맨 위로 버튼을 띄운다.
        static let topButtonOffset: CGFloat = 400
    }

    /// 떠 있는 탭 바 치수 — iOS 26 기본 탭 바와 같은 크기로 그린다.
    private enum DockMetrics {
        static let barHeight: CGFloat = 62
        static let itemWidth: CGFloat = 88
        static let itemHeight: CGFloat = 54
        static let barPadding: CGFloat = 4
        // 홈 막대가 있는 기기에서 탭 바 아래 여백(홈 막대 34 - 17)
        static let homeIndicatorOverlap: CGFloat = 17
        static let minBottomGap: CGFloat = 8
        // 웹 글쓰기 버튼(48, 오른쪽·아래 12)과 같은 크기·여백
        static let circleSize: CGFloat = 48
        static let edgeInset: CGFloat = 12
        // 탭 바 윗변과 웹 글쓰기 버튼 사이
        static let contentGap: CGFloat = 4
    }

    private static let tabBarAnimation: Animation = .easeInOut(duration: 0.5)

    public var body: some View {
        ZStack {
            // 탭별 NavigationStack을 모두 유지하여 탭 전환 시 상태가 보존되도록 한다.
            // 탭 바는 화면 위에 떠 있는 유리 바로 따로 그린다(#267, 아래 overlay). 탭 첫 화면은 그 자리만큼 아래를 비워 두고,
            // 쌓인 화면이 있으면 탭 바는 아래로 내려가 숨는다 — 쌓인 화면은 아래까지 다 쓴다.
            tabContainer(for: .home) {
                NavigationStack(
                    path: $store.scope(state: \.home.path, action: \.home.path)
                ) {
                    CommunityView(store: store.scope(state: \.home, action: \.home))
                        .modifier(tabRootModifier(for: .home))
                } destination: { destinationStore in
                    switch destinationStore.case {
                    case let .detail(detailStore):
                        CommunityDetailView(store: detailStore)
                    case let .userProfile(profileStore):
                        UserProfileView(store: profileStore)
                    case let .myProfile(myStore):
                        MyProfileView(store: myStore)
                    }
                }
            }
            tabContainer(for: .competition) {
                NavigationStack(
                    path: $store.scope(state: \.competition.path, action: \.competition.path)
                ) {
                    // 대회 탭 종의 새 알림 점은 홈이 조회한 값 하나를 함께 쓴다(#258).
                    CompetitionTabView(
                        store: store.scope(state: \.competition, action: \.competition),
                        hasUnreadNotification: store.home.hasUnreadNotification
                    )
                        .modifier(tabRootModifier(for: .competition))
                } destination: { destinationStore in
                    switch destinationStore.case {
                    case let .communityDetail(detailStore):
                        CommunityDetailView(store: detailStore)
                    case let .userProfile(profileStore):
                        UserProfileView(store: profileStore)
                    case let .competitionInfo(competitionInfoStore):
                        CompetitionInfoView(store: competitionInfoStore)
                    }
                }
            }
            tabContainer(for: .myPage) {
                NavigationStack(
                    path: $store.scope(state: \.myPage.path, action: \.myPage.path)
                ) {
                    MyProfileView(store: store.scope(state: \.myPage, action: \.myPage))
                        .modifier(tabRootModifier(for: .myPage))
                } destination: { destinationStore in
                    switch destinationStore.case {
                    case let .communityDetail(detailStore):
                        CommunityDetailView(store: detailStore)
                    case let .userProfile(profileStore):
                        UserProfileView(store: profileStore)
                    case let .settings(settingsStore):
                        SettingsView(store: settingsStore)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.component.navibar.container.background)
        .overlay {
            // 화면 전체를 좌표로 쓴다(웹 글쓰기 버튼과 같은 기준).
            GeometryReader { proxy in
                tabDock(in: proxy.size)
            }
            .ignoresSafeArea()
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { deviceBottomInset = $0 }
        // 탭을 바꾸면 탭 바는 늘 보이게 한다.
        .onChange(of: store.selectedTab) { _, _ in
            withAnimation(Self.tabBarAnimation) { isTabBarHidden = false }
        }
        .fullScreenCover(
            item: $store.scope(state: \.loginCover, action: \.loginCover)
        ) { loginStore in
            LoginView(store: loginStore)
        }
        // OPEN_SUBVIEW(modal) — 게시글 상세를 모달로 띄운다. 모달 내부의 중첩 OPEN_SUBVIEW는
        // 자체 NavigationStack(coverPath)에 push되어 모달 위 모달 중첩을 피한다.
        .fullScreenCover(
            item: $store.scope(state: \.home.detailCover, action: \.home.detailCover)
        ) { coverStore in
            NavigationStack(
                path: $store.scope(state: \.home.coverPath, action: \.home.coverPath)
            ) {
                CommunityDetailView(store: coverStore)
            } destination: { destinationStore in
                switch destinationStore.case {
                case let .detail(detailStore):
                    CommunityDetailView(store: detailStore)
                case let .userProfile(profileStore):
                    UserProfileView(store: profileStore)
                case let .myProfile(myStore):
                    MyProfileView(store: myStore)
                }
            }
            // 모달 안 웹의 '알림 받기'(#257)면 아래 탭 화면의 알럿이 모달에 가려지므로 모달 위에 그린다.
            .appAlert(
                isPresented: deviceNotificationAlertBinding(isInCover: true),
                configuration: deviceNotificationAlertConfiguration
            )
        }
        .appAlert(
            isPresented: Binding(
                get: { store.isLoginPromptPresented },
                set: { if !$0 { store.send(.view(.loginPromptDismissed)) } }
            ),
            configuration: loginPromptAlertConfiguration
        )
        .appAlert(
            isPresented: deviceNotificationAlertBinding(isInCover: false),
            configuration: deviceNotificationAlertConfiguration
        )
        // 리스트 웹뷰가 요청한 확인 알럿·선택 시트를 최상위에서 그려 GNB·하단 탭바까지 덮는다.
        // (웹뷰는 자기 프레임 밖을 딤 처리할 수 없어 이 표면은 네이티브가 소유한다.)
        .webBridgeDialogs(
            confirmDialog: store.home.pendingConfirmDialog,
            selectSheet: store.home.pendingSelectSheet,
            onConfirmButton: { store.send(.home(.view(.confirmDialogButtonTapped($0)))) },
            onConfirmDismiss: { store.send(.home(.view(.confirmDialogDismissed))) },
            onSelectSubmit: { store.send(.home(.view(.selectSheetSubmitted(value: $0, customText: $1)))) },
            onSelectDismiss: { store.send(.home(.view(.selectSheetDismissed))) }
        )
        // 대회 목록 웹의 확인 알럿·선택 시트도 같은 이유로 여기서 그린다(#240).
        .webBridgeDialogs(
            confirmDialog: store.competition.web?.pendingConfirmDialog,
            selectSheet: store.competition.web?.pendingSelectSheet,
            onConfirmButton: { store.send(.competition(.web(.view(.confirmDialogButtonTapped($0))))) },
            onConfirmDismiss: { store.send(.competition(.web(.view(.confirmDialogDismissed)))) },
            onSelectSubmit: { store.send(.competition(.web(.view(.selectSheetSubmitted(value: $0, customText: $1))))) },
            onSelectDismiss: { store.send(.competition(.web(.view(.selectSheetDismissed)))) }
        )
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.view(.sceneBecameActive)) }
        }
    }

    // 게스트가 인증 필요 동작(커뮤니티 글쓰기·대회 관심 등)을 시도할 때 노출되는 공통 로그인 유도 알럿.
    // 특정 화면에 종속되지 않도록 문구를 일반화해 여러 진입점에서 그대로 재사용한다.
    private var loginPromptAlertConfiguration: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "로그인하고 더 많은\n기능을 이용해보세요",
            message: "커뮤니티 참여와 프로필 설정이 가능해요.",
            primaryButton: .init(
                title: "로그인",
                style: .primary,
                action: { store.send(.view(.loginPromptLoginTapped)) }
            ),
            secondaryButton: .init(
                title: "닫기",
                style: .neutral,
                action: { store.send(.view(.loginPromptCancelTapped)) }
            )
        )
    }

    // 기기 알림 꺼짐 안내는 맨 위 화면 한 곳에만 그린다 — 상세 모달이 떠 있으면 모달 위, 아니면 탭 화면 위.
    private func deviceNotificationAlertBinding(isInCover: Bool) -> Binding<Bool> {
        Binding(
            get: { store.isDeviceNotificationAlertPresented && (store.home.detailCover != nil) == isInCover },
            set: { if !$0 { store.send(.view(.deviceNotificationAlertDismissed)) } }
        )
    }

    // 관심 대회 알림을 켰는데 기기 알림이 꺼져 있을 때(#257). 앱은 다시 물을 수 없어 설정 앱으로 보낸다.
    private var deviceNotificationAlertConfiguration: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "기기 알림이 꺼져 있어요",
            message: "설정에서 알림을 켜면 관심 대회 마감 전날 알려 드릴게요.",
            primaryButton: .init(
                title: "설정으로 가기",
                style: .primary,
                action: { store.send(.view(.deviceNotificationAlertSettingsTapped)) }
            ),
            secondaryButton: .init(
                title: "나중에",
                style: .neutral,
                action: { store.send(.view(.deviceNotificationAlertDismissed)) }
            )
        )
    }

    @ViewBuilder
    private func tabContainer<Content: View>(
        for tab: AppTabFeature.Tab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        // 띄울 차례가 아닌 탭은 만들지 않는다. 앱을 켤 때 대회 웹·MY 조회가 홈 피드와 서버를 나눠 쓰지 않게 한다(#271).
        if store.mountedTabs.contains(tab) {
            let isActive = store.selectedTab == tab
            content()
                // 탭은 바로 보이고 사라진다.
                .animation(nil) { $0.opacity(isActive ? 1 : 0) }
                .allowsHitTesting(isActive)
        }
    }

    private func tabRootModifier(for tab: AppTabFeature.Tab) -> TabRootModifier {
        TabRootModifier(
            bottomReserve: max(dockReservedHeight - deviceBottomInset, 0),
            action: TabRootScrollAction { offsetY, maxOffsetY, isUserScrolling in
                handleScroll(tab: tab, offsetY: offsetY, maxOffsetY: maxOffsetY, isUserScrolling: isUserScrolling)
            }
        )
    }

    /// 내리면 탭 바를 숨기고, 올리거나 맨 위 가까이 오면 꺼낸다. 맨 위에서 멀어지면 맨 위로 버튼을 띄운다.
    /// 손으로 움직인 스크롤만 탭 바를 움직인다 — 레이아웃 변화로 생긴 움직임에 다시 꺼내는 되먹임을 막는다.
    private func handleScroll(
        tab: AppTabFeature.Tab,
        offsetY rawOffsetY: CGFloat,
        maxOffsetY: CGFloat,
        isUserScrolling: Bool
    ) {
        guard tab == store.selectedTab else { return }
        // 끝에서 튕기는 동안의 움직임은 방향으로 치지 않는다.
        let offsetY = min(max(rawOffsetY, 0), max(maxOffsetY, 0))

        let isAwayFromTop = offsetY > ScrollMetrics.topButtonOffset
        if tabsAwayFromTop.contains(tab) != isAwayFromTop {
            // 탭 바가 숨은 채 맨 위로 문턱을 넘나들면 동그라미는 제자리에서 사라진다.
            circleExit = .inPlace
            withAnimation(Self.tabBarAnimation) {
                if isAwayFromTop { tabsAwayFromTop.insert(tab) } else { tabsAwayFromTop.remove(tab) }
            }
        }

        let lastOffsetY = scrollTracker.lastOffsetY[tab] ?? offsetY
        var shouldHide = isTabBarHidden
        if offsetY <= ScrollMetrics.revealZone {
            scrollTracker.lastOffsetY[tab] = offsetY
            shouldHide = false
        } else if !isUserScrolling {
            scrollTracker.lastOffsetY[tab] = offsetY
        } else if abs(offsetY - lastOffsetY) >= ScrollMetrics.directionThreshold {
            scrollTracker.lastOffsetY[tab] = offsetY
            shouldHide = offsetY > lastOffsetY
        }
        guard shouldHide != isTabBarHidden else { return }
        // 맨 위에서 먼 채 탭 바가 올라오면, 동그라미는 탭 바의 맨 위로 칸으로 들어간다.
        circleExit = shouldHide ? .inPlace : .slot
        withAnimation(Self.tabBarAnimation) { isTabBarHidden = shouldHide }
    }

    /// 지금 탭의 첫 화면이 맨 앞에 보이는지(위에 쌓인 화면이 없는지)
    private var isTabRootInFront: Bool {
        switch store.selectedTab {
        case .home: store.home.path.isEmpty && store.home.detailCover == nil
        case .competition: store.competition.path.isEmpty
        case .myPage: store.myPage.path.isEmpty
        }
    }

    /// 맨 위로를 띄울 만큼 내려와 있는지. 목록이 긴 웹 탭(홈 피드·대회 목록)만 띄운다.
    private var isAwayFromTopOnListTab: Bool {
        store.selectedTab != .myPage && tabsAwayFromTop.contains(store.selectedTab)
    }

    // MARK: 떠 있는 탭 바(도크)

    /// 탭 바와 맨 위로 동그라미는 따로 움직이는 유리 두 개다(#267).
    /// - 탭 바: 홈·대회·MY (맨 위에서 멀면 맨 위로 칸이 붙어 4칸). 숨길 땐 그대로 아래로 내려간다.
    /// - 동그라미: 탭 바가 숨고 맨 위에서 멀 때의 맨 위로 버튼
    private enum CircleMotion {
        case inPlace
        case slot
    }

    private var isBarShown: Bool {
        isTabRootInFront && !isTabBarHidden
    }

    private var isCircleShown: Bool {
        isTabRootInFront && isTabBarHidden && isAwayFromTopOnListTab
    }

    /// 화면 바닥에서 탭 바 윗변 + 웹 글쓰기 버튼과의 간격까지 — 탭 첫 화면이 이만큼 아래를 비워 둔다.
    /// 탭 바가 숨어도 그대로 둬 웹 글쓰기 버튼·마지막 글이 들썩이지 않는다(움직이는 건 탭 바 하나).
    private var dockReservedHeight: CGFloat {
        dockBottomGap + DockMetrics.barHeight + DockMetrics.contentGap
    }

    private var dockBottomGap: CGFloat {
        max(deviceBottomInset - DockMetrics.homeIndicatorOverlap, DockMetrics.minBottomGap)
    }

    private func barFrame(showsTopItem: Bool, in size: CGSize) -> CGRect {
        let count: CGFloat = showsTopItem ? 4 : 3
        let width = count * DockMetrics.itemWidth + DockMetrics.barPadding * 2
        return CGRect(
            x: (size.width - width) / 2,
            y: size.height - dockBottomGap - DockMetrics.barHeight,
            width: width,
            height: DockMetrics.barHeight
        )
    }

    /// 맨 위로 동그라미 — 오른쪽 맨 아래, 웹 글쓰기 버튼 바로 아래(홈 막대에는 닿지 않게).
    private func circleFrame(in size: CGSize) -> CGRect {
        let writeButtonBottom = dockReservedHeight + DockMetrics.edgeInset
        let bottom = max(writeButtonBottom - DockMetrics.edgeInset - DockMetrics.circleSize, deviceBottomInset + 4)
        return CGRect(
            x: size.width - DockMetrics.edgeInset - DockMetrics.circleSize,
            y: size.height - bottom - DockMetrics.circleSize,
            width: DockMetrics.circleSize,
            height: DockMetrics.circleSize
        )
    }

    /// 탭 바의 맨 위로 칸 아이콘 자리(4칸일 때 맨 오른쪽 칸, 글자 위)
    private func topItemIconCenter(in size: CGSize) -> CGPoint {
        let bar = barFrame(showsTopItem: true, in: size)
        let itemTop = bar.midY - DockMetrics.itemHeight / 2
        return CGPoint(x: bar.maxX - DockMetrics.barPadding - DockMetrics.itemWidth / 2, y: itemTop + 7 + 12)
    }

    private func tabDock(in size: CGSize) -> some View {
        ZStack {
            dockBar(in: size)
            dockCircle(in: size)
        }
    }

    private func dockBar(in size: CGSize) -> some View {
        let isShown = isBarShown
        let showsTopItem = isAwayFromTopOnListTab
        let rest = barFrame(showsTopItem: showsTopItem, in: size)
        // 숨길 땐 모양 그대로 화면 아래로 내린다.
        let frame = isShown ? rest : rest.offsetBy(dx: 0, dy: size.height - rest.minY + 24)
        return HStack(spacing: 0) {
            dockTabItem(.home, title: "홈", asset: Assets.Bottom.Icon.home)
            dockTabItem(.competition, title: "대회", asset: Assets.Bottom.Icon.competition)
            dockTabItem(.myPage, title: "MY", asset: Assets.Bottom.Icon.my)
            if showsTopItem {
                dockTopItem
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, DockMetrics.barPadding)
        .fixedSize()
        .frame(width: frame.width, height: frame.height)
        // 3칸↔4칸으로 폭이 바뀌는 동안 칸이 유리 밖으로 비어져 나오지 않게 한다.
        .clipShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
        .position(x: frame.midX, y: frame.midY)
        .allowsHitTesting(isShown)
        .accessibilityHidden(!isShown)
        .animation(Self.tabBarAnimation, value: isShown)
        .animation(Self.tabBarAnimation, value: showsTopItem)
        .animation(Self.tabBarAnimation, value: store.selectedTab)
    }

    @ViewBuilder
    private func dockCircle(in size: CGSize) -> some View {
        if isCircleShown {
            let frame = circleFrame(in: size)
            let slot = topItemIconCenter(in: size)
            let toSlot = CGSize(width: slot.x - frame.midX, height: slot.y - frame.midY)
            Button {
                scrollCurrentTabToTop()
            } label: {
                chevronUp
                    .frame(width: DockMetrics.circleSize, height: DockMetrics.circleSize)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("맨 위로")
            .position(x: frame.midX, y: frame.midY)
            .transition(.asymmetric(
                // 화면 아래 가장자리 밖에서 제자리로 올라온다.
                insertion: .modifier(
                    active: CircleSlotModifier(offset: CGSize(width: 0, height: size.height - frame.minY + 24), scale: 1, opacity: 1),
                    identity: CircleSlotModifier(offset: .zero, scale: 1, opacity: 1)
                ),
                removal: circleTransition(circleExit, toSlot: toSlot)
            ))
        }
    }

    /// 사라지는 움직임 — 제자리: 살짝 작아지며 흐려진다. 칸: 탭 바의 맨 위로 칸 아이콘 자리로 작아지며 들어간다.
    private func circleTransition(_ motion: CircleMotion, toSlot: CGSize) -> AnyTransition {
        switch motion {
        case .inPlace:
            return .scale(scale: 0.85).combined(with: .opacity)
        case .slot:
            return .modifier(
                active: CircleSlotModifier(offset: toSlot, scale: 0.5, opacity: 0),
                identity: CircleSlotModifier(offset: .zero, scale: 1, opacity: 1)
            )
        }
    }

    private func dockTabItem(_ tab: AppTabFeature.Tab, title: String, asset: ImageAsset) -> some View {
        let isSelected = store.selectedTab == tab
        return Button {
            store.send(.view(.tabSelected(tab)))
        } label: {
            dockItemLabel(
                title: title,
                icon: asset.swiftUIImage.renderingMode(.template).resizable().scaledToFit(),
                isSelected: isSelected
            )
            .background {
                // 고른 칸 밑의 옅은 면 — 다른 칸을 고르면 그쪽으로 미끄러져 간다.
                if isSelected {
                    Capsule()
                        .fill(Color.semantic.surface.containerPressed)
                        .matchedGeometryEffect(id: "selected", in: tabLens)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var dockTopItem: some View {
        Button {
            scrollCurrentTabToTop()
        } label: {
            dockItemLabel(title: "맨 위로", icon: chevronUp, isSelected: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("맨 위로")
    }

    private func dockItemLabel(title: String, icon: some View, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            icon
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? Color.component.navibar.selected.icon : Color.component.navibar.unselected.icon)
            Text(title)
                .font(Font.pretendard.buttonS)
                .foregroundStyle(isSelected ? Color.component.navibar.selected.label : Color.component.navibar.unselected.label)
        }
        .frame(width: DockMetrics.itemWidth, height: DockMetrics.itemHeight)
        .contentShape(Capsule())
    }

    /// kit의 왼쪽 꺾쇠를 위로 돌린 맨 위로 아이콘
    private var chevronUp: some View {
        Assets.Common.Icon.chevronLeft.swiftUIImage
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(90))
            .foregroundStyle(Color.component.header.text)
    }

    private func scrollCurrentTabToTop() {
        switch store.selectedTab {
        case .home: store.send(.home(.view(.tabReselected)))
        case .competition: store.send(.competition(.view(.tabReselected)))
        case .myPage: break
        }
    }
}

/// 맨 위로 동그라미가 탭 바 칸으로 들어가고 나오는 움직임(#267)
private struct CircleSlotModifier: ViewModifier {
    let offset: CGSize
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
    }
}

/// 탭별 마지막 스크롤 위치. 스크롤마다 바뀌어 화면을 다시 그릴 이유가 없어 관찰하지 않는 상자에 둔다.
private final class TabScrollTracker {
    var lastOffsetY: [AppTabFeature.Tab: CGFloat] = [:]
}

/// 탭 첫 화면에 다는 것(#267) — 떠 있는 탭 바 자리만큼 아래를 비우고, 스크롤을 알리는 길을 단다.
private struct TabRootModifier: ViewModifier {
    let bottomReserve: CGFloat
    let action: TabRootScrollAction

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: bottomReserve)
                    .allowsHitTesting(false)
            }
            .environment(\.tabRootScroll, action)
    }
}

// MARK: - Preview
#Preview {
    AppTabView(
        store: Store(
            initialState: AppTabFeature.State(
                authInfo: AuthInfo(
                    accessToken: "preview_access_token",
                    refreshToken: "preview_refresh_token",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "preview@example.com",
                        nickname: "프리뷰유저",
                        profileImageUrl: nil,
                        snsProvider: "APPLE",
                        deactivatedWithinGrace: false
                    )
                )
            )
        ) {
            AppTabFeature()
        }
    )
}
