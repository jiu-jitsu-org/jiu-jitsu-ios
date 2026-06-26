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
        // 웹이 이 화면에 뒤로가기 가드(작성 취소 확인 등)를 등록했는지. true면 네이티브 back은
        // 직접 닫지 않고 BACK_PRESSED를 보내 웹이 닫기를 결정한다. (BACK_GUARD 인바운드로 토글)
        var backGuardEnabled: Bool = false

        // 서브뷰 생성 시점의 access token. WEBVIEW_READY 핸드셰이크 때 초기 로그인 상태를 동기화한다.
        // (세션 연속성은 공유 쿠키가 보장하고, 토큰 주입은 웹 JS 상태 동기화용 보조 채널이다.)
        var accessToken: String?
        // 네이티브 → 웹으로 보낼 브릿지 메시지 대기열.
        var outbox: [WebBridgeOutboundEnvelope] = []

        // 웹이 요청한 확인 알럿/선택 시트(표시 중이면 non-nil). 상세는 이미 풀스크린이라
        // CommunityDetailView가 로컬로 그려도 GNB·탭바까지 덮인다. 한 번에 하나만 표시한다.
        var pendingConfirmDialog: ConfirmDialogPayload?
        var pendingSelectSheet: SelectSheetPayload?

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
            // 공통 네이티브 뒤로가기 버튼 탭.
            // 기본은 네이티브가 직접 닫는다(빠른 경로). 웹이 가드(BACK_GUARD)를 등록한 화면
            // (작성 등)에서만 BACK_PRESSED를 보내 웹이 가드 후 CLOSE_SUBVIEW로 닫게 한다.
            // 로딩/에러는 웹이 응답 불가이므로 가드와 무관하게 직접 닫아 탈출을 보장한다.
            case backTapped

            // MARK: 브릿지 다이얼로그 결과
            case confirmDialogButtonTapped(ConfirmDialogOutcome)
            case confirmDialogDismissed
            case selectSheetSubmitted(value: String, customText: String?)
            case selectSheetDismissed
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
            // 웹뷰 토큰 만료 → 부모가 네이티브 refresh로 갱신 후 결과를 웹에 전파한다.
            case tokenRefreshRequested
        }
    }

    /// 부모(CommunityFeature)가 세션 변화를 상세 웹뷰에도 전파하기 위한 명령.
    /// 상세 웹뷰는 리스트와 다른 WKWebView라, 토큰 갱신/만료 시 별도로 동기화해야 한다.
    public enum SessionUpdate: Sendable, Equatable {
        case loggedIn(accessToken: String)
        case loggedOut
        case sessionExpired
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

            case .view(.backTapped):
                // 기본은 네이티브가 직접 닫는다(빠른 경로). 단, 웹이 이 화면에 가드를 등록했고
                //   (작성 취소 확인 등) 웹이 응답 가능한 상태면 BACK_PRESSED를 보내 웹이 가드 후
                //   CLOSE_SUBVIEW로 닫게 한다. ("계속 작성"이면 웹이 안 닫아 화면 유지)
                // 로딩/에러는 웹 응답 불가이므로 가드와 무관하게 직접 닫아 탈출을 보장한다.
                if state.backGuardEnabled, !state.isLoading, !state.hasError {
                    Self.enqueue(.backPressed, into: &state)
                    return .none
                }
                return .run { _ in await self.dismiss() }

            // MARK: - 브릿지 다이얼로그 결과 (→ 웹 회신)

            case let .view(.confirmDialogButtonTapped(outcome)):
                guard let pending = state.pendingConfirmDialog else { return .none }
                state.pendingConfirmDialog = nil
                Self.enqueue(.confirmDialogResult(requestId: pending.requestId, outcome: outcome), into: &state)
                return .none

            case .view(.confirmDialogDismissed):
                guard let pending = state.pendingConfirmDialog else { return .none }
                state.pendingConfirmDialog = nil
                Self.enqueue(.confirmDialogResult(requestId: pending.requestId, outcome: .dismiss), into: &state)
                return .none

            case let .view(.selectSheetSubmitted(value, customText)):
                guard let pending = state.pendingSelectSheet else { return .none }
                state.pendingSelectSheet = nil
                Self.enqueue(
                    .selectSheetResult(requestId: pending.requestId, outcome: .submit(value: value, customText: customText)),
                    into: &state
                )
                return .none

            case .view(.selectSheetDismissed):
                guard let pending = state.pendingSelectSheet else { return .none }
                state.pendingSelectSheet = nil
                Self.enqueue(.selectSheetResult(requestId: pending.requestId, outcome: .dismiss), into: &state)
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
                        Self.enqueueLoginSuccess(accessToken: accessToken, into: &state)
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

                case let .backGuard(enabled):
                    // 웹이 이 화면의 뒤로가기 가드 유무를 통지 → 네이티브 back 분기에 사용한다.
                    state.backGuardEnabled = enabled
                    return .none

                case let .showConfirmDialog(payload):
                    return Self.presentConfirmDialog(payload, into: &state)

                case let .showSelectSheet(payload):
                    return Self.presentSelectSheet(payload, into: &state)

                case let .authLoginPrompt(reason):
                    return .send(.delegate(.loginPromptRequested(reason: reason)))

                case let .authLoginModal(reason):
                    return .send(.delegate(.loginModalRequested(reason: reason)))

                case .authLogoutRequest:
                    return .send(.delegate(.logoutRequested))

                case .authTokenRefresh:
                    // 상세 웹뷰 토큰 만료 → 네이티브 갱신 위임. 결과는 부모가 SessionUpdate로 다시 내려준다.
                    return .send(.delegate(.tokenRefreshRequested))

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

    /// 부모가 전파한 세션 변화를 상세 웹뷰 상태에 반영한다.
    static func apply(_ update: SessionUpdate, into state: inout State) {
        switch update {
        case let .loggedIn(accessToken):
            guard state.accessToken != accessToken else { return }
            state.accessToken = accessToken
            enqueueLoginSuccess(accessToken: accessToken, into: &state)
        case .loggedOut:
            state.accessToken = nil
            enqueue(.authLogout, into: &state)
        case .sessionExpired:
            state.accessToken = nil
            enqueue(.authSessionExpired, into: &state)
        }
    }

    /// 확인 알럿 표시 요청 처리. 이미 다이얼로그가 떠 있으면 새 요청은 즉시 dismiss로 회신한다.
    private static func presentConfirmDialog(_ payload: ConfirmDialogPayload, into state: inout State) -> Effect<Action> {
        guard state.pendingConfirmDialog == nil, state.pendingSelectSheet == nil else {
            enqueue(.confirmDialogResult(requestId: payload.requestId, outcome: .dismiss), into: &state)
            return .none
        }
        state.pendingConfirmDialog = payload
        return .none
    }

    /// 선택 시트 표시 요청 처리(동시 표시 방지는 presentConfirmDialog와 동일).
    private static func presentSelectSheet(_ payload: SelectSheetPayload, into state: inout State) -> Effect<Action> {
        guard state.pendingConfirmDialog == nil, state.pendingSelectSheet == nil else {
            enqueue(.selectSheetResult(requestId: payload.requestId, outcome: .dismiss), into: &state)
            return .none
        }
        state.pendingSelectSheet = payload
        return .none
    }

    /// 아웃바운드 메시지를 식별자와 함께 대기열에 추가한다.
    private static func enqueue(_ message: WebBridgeOutboundMessage, into state: inout State) {
        state.outbox.append(WebBridgeOutboundEnvelope(id: UUID(), message: message))
    }

    /// AUTH_LOGIN_SUCCESS를 큐에 넣는다.
    private static func enqueueLoginSuccess(accessToken: String, into state: inout State) {
        enqueue(.authLoginSuccess(accessToken: accessToken), into: &state)
    }
}
