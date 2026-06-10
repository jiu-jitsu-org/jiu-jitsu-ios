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

    public init(store: StoreOf<CommunityFeature>) {
        self.store = store
    }

    private enum Metrics {
        // 알림·검색 아이콘 버튼 2곳에서 공유
        static let trailingIconSize: CGFloat = 24
        static let trailingIconButtonSize: CGFloat = 40
    }

    public var body: some View {
        VStack(spacing: 0) {
            gnb
            ZStack {
                if let url = store.url {
                    BridgeWebView(
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
            }
            // SwiftUI 자동 키보드 회피를 끄고, 키보드 대응은 BridgeWebView의 keyboardLayoutGuide
            // 한 곳에서만 처리한다. 글쓰기 화면이 웹 내부 라우트로 열릴 때도 웹뷰 높이만 줄어
            // 웹의 sticky 하단 툴바가 키보드 위에 붙는다. (이중 보정·애니메이션 충돌 방지)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Color.component.background.default)
        .onAppear { store.send(.view(.onAppear)) }
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
            TextField(
                "http://192.168.0.10:3000",
                text: Binding(
                    get: { store.debugURLInput },
                    set: { store.send(.view(.debugURLInputChanged($0))) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)

            Button("적용") { store.send(.view(.debugURLApplyTapped)) }
            Button("기본값 복원", role: .destructive) { store.send(.view(.debugURLResetTapped)) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("불러올 웹뷰 주소를 입력하세요.\n스킴(http/https)을 생략하면 http로 처리됩니다.")
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
