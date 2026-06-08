//
//  CommunityDetailFeature.swift
//  Presentation
//
//  OPEN_SUBVIEW로 열리는 게시글 상세 풀스크린 웹뷰.
//  웹이 자체 헤더(뒤로가기/알림/메뉴)를 그리므로 네이티브 크롬 없이 웹뷰만 렌더한다.
//  CLOSE_SUBVIEW는 @Dependency(\.dismiss)로 자기 자신을 닫고,
//  중첩 OPEN_SUBVIEW·로그인 유도·로그아웃은 부모(CommunityFeature)에 위임한다.
//

import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct CommunityDetailFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        // OPEN_SUBVIEW에서 검증된 동일 origin 절대 URL.
        let url: URL
        // 웹 헤더 렌더 전 임시 제목(선택). 네이티브 크롬이 없어 현재는 보관만 한다.
        let title: String?
        // 같은 URL로 재시도 시 View가 reload를 인지하도록 토큰을 갱신한다.
        var loadToken: UUID = UUID()
        var isLoading: Bool = true
        var hasError: Bool = false

        // 서브뷰 생성 시점의 access token. WEBVIEW_READY 핸드셰이크 때 초기 로그인 상태를 동기화한다.
        // (세션 연속성은 공유 쿠키가 보장하고, 토큰 주입은 웹 JS 상태 동기화용 보조 채널이다.)
        var accessToken: String?
        // 네이티브 → 웹으로 보낼 브릿지 메시지 대기열.
        var outbox: [WebBridgeOutboundEnvelope] = []

        public init(url: URL, title: String? = nil, accessToken: String? = nil) {
            self.url = url
            self.title = title
            self.accessToken = accessToken
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case retryTapped
        }

        public enum InternalAction: Sendable {
            case loadingStarted
            case loadingFinished
            case loadingFailed
            // 웹뷰가 AppBridge로 보내온 인바운드 메시지(WKScriptMessageHandler 경유).
            case bridgeMessageReceived(WebBridgeInboundMessage)
            // View가 outbox의 메시지를 evaluateJavaScript로 전달 완료했음을 통지.
            case outboundDelivered(id: UUID)
        }

        public enum DelegateAction: Sendable {
            // 상세 안에서의 중첩 OPEN_SUBVIEW → 부모가 스택/모달에 쌓는다.
            case openSubviewRequested(OpenSubviewPayload)
            // 비로그인 행위 → 부모가 로그인 유도 알럿/모달을 띄운다.
            case loginPromptRequested(reason: String?)
            case loginModalRequested(reason: String?)
            // 웹 주도 로그아웃 요청 → 부모가 네이티브 로그아웃을 수행한다.
            case logoutRequested
        }
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.retryTapped):
                state.hasError = false
                state.isLoading = true
                state.loadToken = UUID()
                return .none

            case .internal(.loadingStarted):
                state.isLoading = true
                state.hasError = false
                return .none

            case .internal(.loadingFinished):
                state.isLoading = false
                state.hasError = false
                return .none

            case .internal(.loadingFailed):
                state.isLoading = false
                state.hasError = true
                return .none

            // MARK: - Web Bridge (인바운드)

            case let .internal(.bridgeMessageReceived(message)):
                switch message {
                case .webViewReady:
                    // 초기 로그인 상태 동기화: 이미 로그인 상태면 즉시 토큰을 주입한다.
                    if let accessToken = state.accessToken {
                        Self.enqueue(.authLoginSuccess(accessToken: accessToken, expiresAt: nil), into: &state)
                    }
                    return .none

                case let .openSubview(payload):
                    // 동일 origin이 아니거나 URL을 만들 수 없으면 무시한다(세션 쿠키 유출 방지).
                    guard
                        let target = URL(string: payload.url),
                        WebOrigin.isSameOrigin(target, as: state.url)
                    else {
                        Log.trace("상세 OPEN_SUBVIEW 무시(잘못된 URL/교차 출처): \(payload.url)", category: .network, level: .error)
                        return .none
                    }
                    return .send(.delegate(.openSubviewRequested(payload)))

                case .closeSubview:
                    // 자기 자신(최상단 서브뷰)을 닫는다. 스택 push면 pop, 모달이면 dismiss된다.
                    return .run { _ in await self.dismiss() }

                case let .authLoginPrompt(reason):
                    return .send(.delegate(.loginPromptRequested(reason: reason)))

                case let .authLoginModal(reason):
                    return .send(.delegate(.loginModalRequested(reason: reason)))

                case .authLogoutRequest:
                    return .send(.delegate(.logoutRequested))

                case let .unknown(type):
                    Log.trace("WebBridge 미지원 메시지 무시: \(type)", category: .network, level: .info)
                    return .none
                }

            case let .internal(.outboundDelivered(id)):
                state.outbox.removeAll { $0.id == id }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    /// 아웃바운드 메시지를 식별자와 함께 대기열에 추가한다.
    private static func enqueue(_ message: WebBridgeOutboundMessage, into state: inout State) {
        state.outbox.append(WebBridgeOutboundEnvelope(id: UUID(), message: message))
    }
}
