//
//  CommunityDetailView.swift
//  Presentation
//
//  OPEN_SUBVIEW로 열리는 게시글 상세 풀스크린 웹뷰.
//  웹이 자체 헤더를 그리므로 네이티브 내비게이션 바를 숨겨 chromeless로 렌더한다.
//  (탭바는 부모 AppTabView가 서브뷰 push 시 숨긴다.)
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import CoreKit

public struct CommunityDetailView: View {
    let store: StoreOf<CommunityDetailFeature>

    public init(store: StoreOf<CommunityDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            BridgeWebView(
                url: store.url,
                loadToken: store.loadToken,
                outbox: store.outbox,
                // 웹 헤더의 뒤로가기(CLOSE_SUBVIEW)로 닫으므로 좌우 스와이프 제스처는 끈다.
                allowsBackForwardNavigationGestures: false,
                // 상세는 스크롤/상태 보존을 위해 풀다운 리프레시를 끈다.
                enablesPullToRefresh: false,
                onLoadingStarted: { store.send(.internal(.loadingStarted)) },
                onLoadingFinished: { store.send(.internal(.loadingFinished)) },
                onLoadingFailed: { store.send(.internal(.loadingFailed)) },
                onBridgeMessage: { store.send(.internal(.bridgeMessageReceived($0))) },
                onOutboundDelivered: { store.send(.internal(.outboundDelivered(id: $0))) }
            )

            if store.isLoading {
                loadingOverlay
            }

            if store.hasError {
                errorOverlay
            }
        }
        .background(Color.component.background.default)
        // chromeless: 네이티브 내비게이션 바를 숨겨 웹 자체 헤더만 보이게 한다.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        // chromeless 일관성: 상태바(상단 safe area)까지 웹이 자체 헤더로 직접 그리도록
        // 웹뷰를 화면 최상단·최하단까지 확장한다. (네이티브가 상태바를 회색으로 칠하던 문제 제거)
        // ⚠️ 웹 의존성: 웹 HTML <meta viewport>에 `viewport-fit=cover`를, 상단 헤더에
        //    `padding-top: env(safe-area-inset-top)`를 적용해야 시계/배터리와 헤더가 겹치지 않는다.
        //    (BridgeWebView는 contentInsetAdjustmentBehavior=.never로 safe area 보정을 웹에 위임한다.)
        // .keyboard는 하단만 무시 — SwiftUI 자동 키보드 회피를 끄고 키보드 대응은
        //    BridgeWebView의 keyboardLayoutGuide 한 곳에서만 처리해 이중 보정·애니메이션 충돌을 막는다.
        //    (웹의 sticky 하단 툴바가 키보드 위에 자연스럽게 붙도록 웹뷰 높이만 줄인다.)
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.component.background.default)
    }

    private var errorOverlay: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.component.background.default)
    }
}
