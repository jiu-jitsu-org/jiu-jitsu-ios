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
        // 탭바가 사라진 하단 영역까지 웹뷰가 채우도록 한다.
        .ignoresSafeArea(.container, edges: .bottom)
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
