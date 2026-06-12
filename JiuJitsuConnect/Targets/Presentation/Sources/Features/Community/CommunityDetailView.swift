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
        // 외부 ZStack은 safe area를 존중 → 네이티브 뒤로가기를 상태바 아래에 둘 수 있다.
        // (안쪽 웹뷰 레이어만 ignoresSafeArea로 edge-to-edge 확장)
        ZStack(alignment: .topLeading) {
            webViewLayer
            backButton
                .padding(.leading, 8)
                // 웹 헤더(높이 44) 바 안에서 40pt 버튼을 세로 중앙 정렬: (44-40)/2
                .padding(.top, 2)
        }
        // chromeless: 네이티브 내비게이션 바를 숨겨 웹 자체 헤더만 보이게 한다.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var webViewLayer: some View {
        ZStack {
            BridgeWebView(
                url: store.url,
                loadToken: store.loadToken,
                outbox: store.outbox,
                // 웹 헤더의 뒤로가기(CLOSE_SUBVIEW)로 닫으므로 좌우 스와이프 제스처는 끈다.
                allowsBackForwardNavigationGestures: false,
                // 상세는 스크롤/상태 보존을 위해 풀다운 리프레시를 끈다.
                enablesPullToRefresh: false,
                // 키보드가 문서를 밀어올려 고정 헤더가 화면 밖으로 나가는 것을 막는다.
                locksDocumentScroll: true,
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
        // 키보드 회피로 웹뷰가 줄었다 복귀하는 사이 드러나는 영역까지 흰색을 유지한다.
        // 웹 콘텐츠가 #ffffff이므로 배경도 동일한 흰색으로 둬야 회색 갭이 보이지 않는다.
        .background(Color.primitive.bw.trueWhite)
        // chromeless 일관성: 상단(상태바)·하단(홈 인디케이터) safe area를 모두 무시해
        // 웹뷰를 화면 끝까지 확장한다. 웹이 자체 헤더/툴바로 노치 영역까지 직접 그린다.
        // chained ignoresSafeArea는 합성이 불안정해 .container·.keyboard를 단일 modifier로
        // 한 번에 무시한다. (분리하면 하단 container 무시가 되돌아가 홈 인디케이터에 배경색이 샌다)
        // .keyboard 무시로 SwiftUI 자동 키보드 회피를 끄고, 키보드 대응은 BridgeWebView의
        // keyboardLayoutGuide 한 곳에서만 처리해 이중 보정·애니메이션 충돌을 막는다.
        // ⚠️ 웹 의존성: 웹 HTML <meta viewport>에 viewport-fit=cover, 헤더/툴바에
        //    padding(env(safe-area-inset-top/bottom))을 적용해야 시계·홈인디케이터와 안 겹친다.
        //    (BridgeWebView는 contentInsetAdjustmentBehavior=.never로 safe area 보정을 웹에 위임)
        .ignoresSafeArea([.container, .keyboard], edges: [.top, .bottom])
    }

    // 공통 네이티브 뒤로가기 — 웹이 헤더에서 뺀 좌측 자리에 항상 노출되어, 웹 헤더가 못 떠도
    // (로딩/에러) 빠져나갈 수 있게 한다. 아이콘 24x24 / 터치영역 40x40 / 좌측 여백 8.
    private var backButton: some View {
        Button {
            store.send(.view(.backTapped))
        } label: {
            Assets.Common.Icon.chevronLeft.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.component.header.iconButton)
                .frame(width: 40, height: 40)
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
