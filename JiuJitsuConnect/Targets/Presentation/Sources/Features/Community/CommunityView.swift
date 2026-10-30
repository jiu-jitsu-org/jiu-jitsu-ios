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
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<CommunityFeature>) {
        self.store = store
    }

    private enum Metrics {
        // 알림·검색·내 사진 버튼에서 공유
        static let trailingIconSize: CGFloat = 24
        static let trailingIconButtonSize: CGFloat = 40
        // 새 알림 점: 6pt 원 + 바깥 1pt 테두리. 빨간 원이 종 아이콘(24pt) 상단에 딱 붙고 오른쪽에서 1pt 안쪽에 겹친다.
        static let notificationDotSize: CGFloat = 6
        static let notificationDotStrokeWidth: CGFloat = 1
        static let notificationDotTrailingInset: CGFloat = 1
        // 내 사진: 28pt 원을 다른 아이콘과 같은 터치 영역 가운데에 둔다. 사진이 없으면 기본 사람 아이콘.
        static let avatarSize: CGFloat = 28
        static let avatarDefaultIconSize: CGFloat = 20
    }

    public var body: some View {
        VStack(spacing: 0) {
            gnb
            ZStack {
                if let url = store.url {
                    BridgeWebView(
                        source: .list,
                        url: url,
                        loadToken: store.loadToken,
                        accessToken: store.accessToken,
                        outbox: store.outbox,
                        // 리스트 피드 웹 배경과 맞춰, 바운스 때 다른 색이 드러나지 않게 한다.
                        overscrollBackground: Color.primitive.bw.white,
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
            }
            // SwiftUI 자동 키보드 회피를 끄고, 키보드 대응은 BridgeWebView의 keyboardLayoutGuide
            // 한 곳에서만 처리한다. 글쓰기 화면이 웹 내부 라우트로 열릴 때도 웹뷰 높이만 줄어
            // 웹의 sticky 하단 툴바가 키보드 위에 붙는다. (이중 보정·애니메이션 충돌 방지)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Color.component.background.default)
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.view(.sceneBecameActive)) }
        }
        .modifier(DebugDomainAlert(store: store))
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
                        Button {
                            store.send(.view(.notificationTapped))
                        } label: {
                            Assets.Common.Icon.inbox.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: Metrics.trailingIconSize, height: Metrics.trailingIconSize)
                                .foregroundStyle(Color.component.header.iconButton)
                                .overlay(alignment: .topTrailing) {
                                    if store.hasUnreadNotification {
                                        notificationDot
                                    }
                                }
                                .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

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

                    if store.isMyProfileButtonVisible {
                        Button {
                            store.send(.view(.myProfileTapped))
                        } label: {
                            myAvatar
                                .frame(width: Metrics.trailingIconButtonSize, height: Metrics.trailingIconButtonSize)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("내 프로필")
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
        .frame(height: 44)
        // 헤더 흰색을 상단 safe area(상태바)까지 끌어올려 회색(background.default)이
        // 상태바에 번지지 않게 한다. gnb가 VStack 최상단이라 top safe area 무시가 곧 상태바 채움.
        .background {
            Color.component.header.background
                .ignoresSafeArea(edges: .top)
        }
    }

    // 사진이 없거나 불러오는 중·실패면 회색 원 위 기본 사람 아이콘을 그린다(웹 아바타와 같은 처리).
    private var myAvatar: some View {
        Group {
            // URL이 nil로 바뀌어도 같은 AsyncImage는 직전에 받은 사진을 계속 그린다(사진 삭제 후 이전 사진이 남던 원인).
            // 그래서 사진이 없으면 AsyncImage를 아예 빼고 기본 아이콘을 직접 그린다.
            if let url = store.myProfileImageURL {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        myAvatarPlaceholder
                    }
                }
            } else {
                myAvatarPlaceholder
            }
        }
        .frame(width: Metrics.avatarSize, height: Metrics.avatarSize)
        .clipShape(Circle())
    }

    private var myAvatarPlaceholder: some View {
        ZStack {
            Color.component.header.avatarPlaceholder
            Assets.Common.Icon.avatarDefault.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.avatarDefaultIconSize, height: Metrics.avatarDefaultIconSize)
                .foregroundStyle(Color.component.header.avatarDefaultIcon)
        }
    }

    // 테두리는 바깥(outside) 정렬이라 6pt 원 뒤에 테두리 두께만큼 큰 원을 깔아 표현한다.
    // 위치는 빨간 원 기준이라 테두리는 아이콘 위·오른쪽 바깥으로 1pt씩 걸칠 수 있다.
    private var notificationDot: some View {
        Circle()
            .fill(Color.primitive.red.notification)
            .frame(width: Metrics.notificationDotSize, height: Metrics.notificationDotSize)
            .background {
                Circle()
                    .fill(Color.primitive.bw.white)
                    .padding(-Metrics.notificationDotStrokeWidth)
            }
            .padding(.trailing, Metrics.notificationDotTrailingInset)
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
