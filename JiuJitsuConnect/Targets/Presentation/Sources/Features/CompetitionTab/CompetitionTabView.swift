//
//  CompetitionTabView.swift
//  Presentation
//
//  하단 탭 '대회'(#240). 머리줄은 앱이, 목록은 웹이 그린다 — 웹은 앱 머리줄·탭바 사이에 들어가
//  안전 영역 여백을 따로 두지 않는다(홈 피드와 같은 기준, 웹 #332).
//

import SwiftUI
import ComposableArchitecture
import CoreKit
import DesignSystem

public struct CompetitionTabView: View {
    let store: StoreOf<CompetitionTabFeature>
    // 알림함 종의 새 알림 점(#258). 홈이 조회해 둔 값 하나만 따라 그려, 두 탭의 점이 어긋나지 않게 한다.
    let hasUnreadNotification: Bool

    public init(store: StoreOf<CompetitionTabFeature>, hasUnreadNotification: Bool) {
        self.store = store
        self.hasUnreadNotification = hasUnreadNotification
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                if let webStore = store.scope(state: \.web, action: \.web) {
                    CompetitionListWebView(store: webStore, scrollToTopToken: store.scrollToTopToken, headerTint: headerTint)
                } else {
                    errorMessage
                }
            }
            // 키보드 대응은 BridgeWebView 한 곳에서만 한다(홈 피드와 같음).
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Color.component.background.default)
        .toolbar(.hidden, for: .navigationBar)
    }

    // 웹이 알린 목록 맨 위 색. 없으면 nil(기본 머리줄).
    private var headerTint: Color? { store.headerTint.map { Color(hex: $0) } }

    // 홈 머리줄(높이 44 · 왼쪽 16 · 오른쪽 8 · 아래 구분선)과 같은 자리에 탭 이름과 알림함 종을 둔다.
    // 종 앞에는 웹이 상태를 알려 온 동안만 ♡(관심 대회만)·달력/목록 버튼을 둔다(#266). 종은 홈처럼 맨 오른쪽에 남긴다.
    private var header: some View {
        ZStack(alignment: .bottom) {
            // 웹 그라데이션과 한 면으로 이어질 때는 구분선을 숨긴다.
            if headerTint == nil {
                Rectangle()
                    .fill(Color.component.navibar.container.divider)
                    .frame(height: 1)
            }

            HStack(spacing: 0) {
                Text("대회")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.header.text)
                Spacer(minLength: 0)
                if let actions = store.visibleHeaderActions {
                    CompetitionHeaderActionButtons(actions: actions) {
                        store.send(.view(.headerActionTapped($0)))
                    }
                }
                if store.isNotificationButtonVisible {
                    NotificationInboxButton(hasUnread: hasUnreadNotification) {
                        store.send(.view(.notificationTapped))
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
        .frame(height: 44)
        // 홈 머리줄과 같은 흰 바탕(웹이 색을 알리면 그 색)을 상태바까지 끌어올린다.
        // 웹이 스크롤하며 조금씩 다른 색을 연달아 보내므로 애니메이션 없이 바로 바꾼다.
        .background {
            (headerTint ?? Color.component.header.background)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var errorMessage: some View {
        Text("잠시 문제가 생겼어요")
            .font(.pretendard.bodyM)
            .foregroundStyle(Color.component.errorState.default.titleText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 대회 탭 머리줄의 ♡(관심 대회만 보기)·달력/목록 전환 버튼(#266). 알림함 종과 같은 크기(아이콘 24 · 버튼 40)다.
/// 누르면 웹에 넘기기만 하고, 모양은 웹이 다시 알려 준 상태(actions)로만 바뀐다.
private struct CompetitionHeaderActionButtons: View {
    let actions: CompetitionHeaderActionsPayload
    let onTap: (CompetitionHeaderAction) -> Void

    private enum Metrics {
        static let iconSize: CGFloat = 24
        static let buttonSize: CGFloat = 40
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                onTap(.toggleInterested)
            } label: {
                // 켜짐은 웹 관심 하트(reaction-bar active like-icon, #FF1D0D)와 같은 빨강으로 채운다.
                icon(
                    actions.interestedOnly ? Assets.Common.Icon.heartFill.swiftUIImage : Assets.Common.Icon.heart.swiftUIImage,
                    color: actions.interestedOnly ? Color.primitive.red.r500 : Color.component.header.iconButton
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("관심 대회만 보기")
            .accessibilityValue(actions.interestedOnly ? "켜짐" : "꺼짐")

            Button {
                onTap(.toggleMode)
            } label: {
                // 지금 모양이 아니라 눌렀을 때 갈 모양을 보여 준다(목록이면 달력, 달력이면 목록).
                icon(
                    actions.mode == .list ? Assets.Common.Icon.calendar.swiftUIImage : Assets.Common.Icon.list.swiftUIImage,
                    color: Color.component.header.iconButton
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(actions.mode == .list ? "달력으로 보기" : "목록으로 보기")
        }
    }

    // 웹 필터 줄과 같은 그림(웹 heart·calendar·list 아이콘을 옮긴 템플릿 SVG)을 종과 같은 24pt로 그린다.
    private func icon(_ image: Image, color: Color) -> some View {
        image
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
            .frame(width: Metrics.buttonSize, height: Metrics.buttonSize)
            .contentShape(Rectangle())
    }
}

/// 대회 목록 웹뷰 + 로딩·오류 덮개. 탭 첫 화면이라 상세 웹과 달리 뒤로가기를 두지 않는다.
private struct CompetitionListWebView: View {
    let store: StoreOf<CommunityDetailFeature>
    let scrollToTopToken: UUID?
    let headerTint: Color?

    var body: some View {
        ZStack {
            BridgeWebView(
                source: .detail(store.url),
                url: store.url,
                loadToken: store.loadToken,
                scrollToTopToken: scrollToTopToken,
                accessToken: store.accessToken,
                outbox: store.outbox,
                // 목록 웹 배경(surface-container)과 맞춰 바운스 때 다른 색이 드러나지 않게 한다.
                overscrollBackground: Color.primitive.bw.white,
                // 머리줄이 칠해져 있으면 맨 위에서 당길 때 드러나는 밴드도 같은 색으로 이어 준다.
                pullToRefreshBackground: headerTint,
                capabilities: store.capabilities,
                onLoadingStarted: { store.send(.internal(.loadingStarted)) },
                onLoadingFinished: { store.send(.internal(.loadingFinished)) },
                onLoadingFailed: { store.send(.internal(.loadingFailed)) },
                onBridgeMessage: { store.send(.internal(.bridgeMessageReceived($0))) },
                onOutboundDelivered: { store.send(.internal(.outboundDelivered(id: $0))) }
            )

            WebLoadingOverlay(isLoading: store.isLoading)

            if store.hasError {
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
        // 웹이 요청한 확인 알럿·선택 시트는 탭바까지 덮도록 AppTabView가 그린다(홈 피드와 같음).
    }
}

#Preview {
    CompetitionTabView(
        store: Store(initialState: CompetitionTabFeature.State(base: URL(string: "https://example.com"), accessToken: "preview")) {
            CompetitionTabFeature()
        },
        hasUnreadNotification: true
    )
}
