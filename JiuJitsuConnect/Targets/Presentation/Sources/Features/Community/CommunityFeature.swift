//
//  CommunityFeature.swift
//  Presentation
//
//  커뮤니티 탭 컨테이너 — 외부 웹 페이지를 WKWebView로 렌더링한다.
//  실제 커뮤니티 기능(피드/글쓰기 등)은 웹쪽에서 구현되며,
//  여기서는 URL 로딩 상태(로딩/에러/재시도)만 TCA로 관리한다.
//

import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct CommunityFeature: Sendable {
    public init() {}

    public enum Tab: String, CaseIterable, Sendable, Equatable {
        case feed
        case category

        var title: String {
            switch self {
            case .feed: return "피드"
            case .category: return "카테고리"
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .feed
        var url: URL?
        // 같은 URL로 재시도 시 View가 reload를 인지하도록 토큰을 갱신한다.
        var loadToken: UUID = UUID()
        var isLoading: Bool = true
        var hasError: Bool = false

        // 현재 백엔드 access token. 로그인 상태면 값이 있고, 게스트면 nil.
        // WEBVIEW_READY 핸드셰이크 시 초기 로그인 상태 동기화에 사용한다.
        // (정책: 웹에는 accessToken만 전달, refreshToken은 네이티브 Keychain에만 보관)
        var accessToken: String?
        // 네이티브 → 웹으로 보낼 브릿지 메시지 대기열. View가 evaluateJavaScript로
        // 전달한 뒤 outboundDelivered로 제거한다.
        var outbox: [WebBridgeOutboundEnvelope] = []

        // 테스트용 웹뷰 도메인 변경 입력 다이얼로그 상태. (DEBUG/BETA 빌드에서만 노출)
        var isDebugURLAlertPresented = false
        var debugURLInput = ""

        // OPEN_SUBVIEW(push)로 쌓이는 게시글 상세 서브뷰 스택. 중첩 OPEN_SUBVIEW도 여기에 push된다.
        var path = StackState<Path.State>()
        // OPEN_SUBVIEW(modal)로 띄우는 상세 서브뷰(모달 루트).
        @Presents var detailCover: CommunityDetailFeature.State?
        // 모달 내부에서의 중첩 OPEN_SUBVIEW가 쌓이는 별도 스택(모달 위 NavigationStack 전용).
        var coverPath = StackState<Path.State>()

        public init(accessToken: String? = nil) {
            self.accessToken = accessToken
            let url = CommunityFeature.makeCommunityURL()
            self.url = url
            // URL 자체를 만들 수 없으면 WKWebView가 생성되지 않아 로딩 콜백이 영영 오지 않는다.
            // 사용자에게 무한 로딩 대신 재시도 오버레이를 보여주기 위해 에러 상태로 초기화한다.
            if url == nil {
                self.isLoading = false
                self.hasError = true
            }
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        // 부모(AppTabFeature)가 세션 변화를 주입해 웹뷰에 전파시키는 통로.
        case session(SessionAction)

        // 게시글 상세 서브뷰 네비게이션.
        case path(StackAction<Path.State, Path.Action>)
        case coverPath(StackAction<Path.State, Path.Action>)
        case detailCover(PresentationAction<CommunityDetailFeature.Action>)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
            case tabSelected(Tab)
            case notificationTapped
            case searchTapped

            // MARK: 테스트용 웹뷰 도메인 변경
            // IP/도메인을 입력받아 즉시 해당 주소의 웹뷰를 다시 로드한다. (DEBUG/BETA 전용)
            case debugChangeDomainTapped
            case debugURLInputChanged(String)
            case debugURLApplyTapped
            case debugURLResetTapped
            case debugURLAlertDismissed
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
            // 비로그인 행위 시도 → 부모가 "로그인이 필요해요" 안내 알럿을 띄운다.
            case loginPromptRequested(reason: String?)
            // 비로그인 행위 시도 → 부모가 로그인 모달을 즉시 띄운다(다이렉트).
            case loginModalRequested(reason: String?)
            // 웹 주도 로그아웃 요청(선택) → 부모가 네이티브 로그아웃을 수행한다.
            case logoutRequested
        }

        /// 부모가 세션 상태 변화를 알려주면 그에 맞는 아웃바운드 메시지를 웹에 주입한다.
        public enum SessionAction: Sendable {
            case loggedIn(accessToken: String, expiresAt: Int?)
            case loginCancelled
            case loggedOut
            case sessionExpired
        }
    }

    @Reducer
    public enum Path: Sendable {
        case detail(CommunityDetailFeature)
    }

    /// 중첩 서브뷰가 어느 컨테이너(푸시 스택 / 모달 내부 스택)에서 올라왔는지 구분한다.
    private enum SubviewContainer {
        case push
        case modal
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                if state.url == nil {
                    state.url = Self.makeCommunityURL()
                }
                return .none

            case let .view(.tabSelected(tab)):
                state.selectedTab = tab
                return .none

            // FIXME: 알림 화면 진입 (네이티브 알림 센터 도입 시 구현)
            case .view(.notificationTapped):
                return .none

            // FIXME: 검색 화면 진입 (커뮤니티 검색 기능 도입 시 구현)
            case .view(.searchTapped):
                return .none

            case .view(.retryTapped):
                // URL이 아직도 nil이면 WKWebView가 생성되지 않으므로 재시도해도 콜백이 오지 않는다.
                // 다시 만들어보고, 그래도 실패하면 에러 상태를 유지한다.
                if state.url == nil {
                    state.url = Self.makeCommunityURL()
                }
                guard state.url != nil else {
                    state.hasError = true
                    state.isLoading = false
                    return .none
                }
                state.hasError = false
                state.isLoading = true
                state.loadToken = UUID()
                return .none

            // MARK: - 테스트용 웹뷰 도메인 변경

            case .view(.debugChangeDomainTapped):
                // 현재 적용된 주소를 입력 필드 기본값으로 채워 수정 출발점을 제공한다.
                state.debugURLInput = state.url?.absoluteString ?? ""
                state.isDebugURLAlertPresented = true
                return .none

            case let .view(.debugURLInputChanged(text)):
                state.debugURLInput = text
                return .none

            case .view(.debugURLApplyTapped):
                state.isDebugURLAlertPresented = false
                Self.setDebugOverrideURLString(Self.normalizedURLString(state.debugURLInput))
                Self.reloadCommunity(&state)
                return .none

            case .view(.debugURLResetTapped):
                // 오버라이드를 지우면 다시 Info.plist의 WEB_URL로 로드된다.
                state.isDebugURLAlertPresented = false
                Self.setDebugOverrideURLString(nil)
                Self.reloadCommunity(&state)
                return .none

            case .view(.debugURLAlertDismissed):
                state.isDebugURLAlertPresented = false
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
                    // 초기 로그인 상태 동기화: 이미 로그인 상태면 즉시 토큰을 주입하고,
                    // 게스트면 아무것도 보내지 않는다(웹은 비로그인 상태로 시작).
                    if let accessToken = state.accessToken {
                        Self.enqueue(.authLoginSuccess(accessToken: accessToken, expiresAt: nil), into: &state)
                    }
                    return .none

                case let .authLoginPrompt(reason):
                    return .send(.delegate(.loginPromptRequested(reason: reason)))

                case let .authLoginModal(reason):
                    return .send(.delegate(.loginModalRequested(reason: reason)))

                case .authLogoutRequest:
                    return .send(.delegate(.logoutRequested))

                case let .openSubview(payload):
                    return Self.openSubview(payload, from: .push, into: &state)

                case .closeSubview:
                    // 리스트 웹뷰에는 닫을 서브뷰가 없다. 상세 웹뷰의 CLOSE는 각 상세가 처리한다.
                    Log.trace("리스트 웹뷰 CLOSE_SUBVIEW 수신 — 무시", category: .network, level: .info)
                    return .none

                case .backGuard:
                    // 뒤로가기 가드는 서브뷰(상세) 전용 — 리스트에는 네이티브 back이 없어 무시한다.
                    return .none

                case let .unknown(type):
                    // 계약에 없는 타입 — 한쪽만 먼저 배포된 경우를 대비해 무시한다.
                    Log.trace("WebBridge 미지원 메시지 무시: \(type)", category: .network, level: .info)
                    return .none
                }

            case let .internal(.outboundDelivered(id)):
                state.outbox.removeAll { $0.id == id }
                return .none

            // MARK: - Session (부모 주입 → 아웃바운드)

            case let .session(.loggedIn(accessToken, expiresAt)):
                state.accessToken = accessToken
                Self.enqueue(.authLoginSuccess(accessToken: accessToken, expiresAt: expiresAt), into: &state)
                return .none

            case .session(.loginCancelled):
                Self.enqueue(.authLoginCancelled, into: &state)
                return .none

            case .session(.loggedOut):
                state.accessToken = nil
                Self.enqueue(.authLogout, into: &state)
                return .none

            case .session(.sessionExpired):
                state.accessToken = nil
                Self.enqueue(.authSessionExpired, into: &state)
                return .none

            // MARK: - Subview Delegates (상세 서브뷰 → 부모)

            // 푸시 스택의 상세에서 올라온 위임.
            case let .path(.element(id: _, action: .detail(.delegate(delegate)))):
                return Self.handleDetailDelegate(delegate, from: .push, into: &state)

            // 모달 내부 스택의 상세에서 올라온 위임.
            case let .coverPath(.element(id: _, action: .detail(.delegate(delegate)))):
                return Self.handleDetailDelegate(delegate, from: .modal, into: &state)

            // 모달 루트 상세에서 올라온 위임.
            case let .detailCover(.presented(.delegate(delegate))):
                return Self.handleDetailDelegate(delegate, from: .modal, into: &state)

            case .path, .coverPath, .detailCover:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$detailCover, action: \.detailCover) {
            CommunityDetailFeature()
        }
        .forEach(\.path, action: \.path)
        .forEach(\.coverPath, action: \.coverPath)
    }

    // MARK: - Subview 라우팅 헬퍼

    /// 상세 서브뷰의 위임을 받아 스택/모달을 갱신하거나, 인증류는 부모(AppTab)로 다시 위임한다.
    private static func handleDetailDelegate(
        _ delegate: CommunityDetailFeature.Action.DelegateAction,
        from container: SubviewContainer,
        into state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case let .openSubviewRequested(payload):
            // 이미 서브뷰 안이므로 같은 컨테이너에 push로 쌓는다(모달 위 모달 중첩 방지).
            return openSubview(payload, from: container, into: &state)
        case let .loginPromptRequested(reason):
            return .send(.delegate(.loginPromptRequested(reason: reason)))
        case let .loginModalRequested(reason):
            return .send(.delegate(.loginModalRequested(reason: reason)))
        case .logoutRequested:
            return .send(.delegate(.logoutRequested))
        }
    }

    /// OPEN_SUBVIEW를 동일 origin 검증 후 push/modal로 표시한다.
    /// - 리스트(.push 컨테이너)에서의 modal 요청만 모달로 띄우고,
    ///   서브뷰 안에서의 중첩 요청은 현재 컨테이너에 push로 강등한다(모달 중첩 방지).
    private static func openSubview(
        _ payload: OpenSubviewPayload,
        from container: SubviewContainer,
        into state: inout State
    ) -> Effect<Action> {
        guard
            let base = state.url,
            let target = URL(string: payload.url),
            WebOrigin.isSameOrigin(target, as: base)
        else {
            Log.trace("OPEN_SUBVIEW 무시(잘못된 URL/교차 출처): \(payload.url)", category: .network, level: .error)
            return .none
        }

        let detail = CommunityDetailFeature.State(
            url: target,
            title: payload.title,
            accessToken: state.accessToken
        )

        switch container {
        case .push:
            switch payload.presentation {
            case .push:
                state.path.append(.detail(detail))
            case .modal:
                // 새 모달을 띄우기 전, 이전 모달의 잔여 내부 스택을 비워 신선한 상태로 연다.
                state.coverPath = .init()
                state.detailCover = detail
            }
        case .modal:
            if payload.presentation == .modal {
                Log.trace("중첩 OPEN_SUBVIEW presentation=modal → 모달 내부 push로 강등", category: .network, level: .info)
            }
            state.coverPath.append(.detail(detail))
        }
        return .none
    }

    /// 아웃바운드 메시지를 식별자와 함께 대기열에 추가한다.
    private static func enqueue(_ message: WebBridgeOutboundMessage, into state: inout State) {
        state.outbox.append(WebBridgeOutboundEnvelope(id: UUID(), message: message))
    }

    private static func makeCommunityURL() -> URL? {
#if DEBUG || BETA
        // 테스트용 도메인 오버라이드가 설정돼 있으면 WEB_URL보다 우선 사용한다.
        if let override = debugOverrideURL() {
            Log.trace("커뮤니티 웹뷰 도메인 오버라이드 사용: \(override.absoluteString)", category: .system, level: .info)
            return override
        }
#endif
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "WEB_URL") as? String,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            Log.trace("WEB_URL is not set in Info.plist", category: .system, level: .error)
            return nil
        }
        return url
    }

    // MARK: - 테스트용 도메인 오버라이드 (UserDefaults)

    private static let debugURLOverrideKey = "debug.community.webURLOverride"

    /// 입력 주소로 URL을 다시 만들고 강제 reload되도록 상태를 초기화한다.
    private static func reloadCommunity(_ state: inout State) {
        let url = makeCommunityURL()
        state.url = url
        // URL이 동일해도 View가 reload를 인지하도록 토큰을 갱신한다.
        state.loadToken = UUID()
        // 도메인이 바뀌면 이전 웹 컨텍스트의 전달 대기 메시지는 의미가 없다.
        state.outbox.removeAll()
        if url == nil {
            state.isLoading = false
            state.hasError = true
        } else {
            state.isLoading = true
            state.hasError = false
        }
    }

    /// 사용자가 입력한 문자열을 로드 가능한 URL 문자열로 정규화한다.
    /// 스킴을 생략하면(`192.168.0.10:3000`) http로 처리해 ip만 입력해도 바로 열리게 한다.
    private static func normalizedURLString(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.contains("://") ? trimmed : "http://\(trimmed)"
    }

    private static func setDebugOverrideURLString(_ value: String?) {
        let defaults = UserDefaults.standard
        if let value, !value.isEmpty {
            defaults.set(value, forKey: debugURLOverrideKey)
        } else {
            defaults.removeObject(forKey: debugURLOverrideKey)
        }
    }

#if DEBUG || BETA
    private static func debugOverrideURL() -> URL? {
        guard
            let override = UserDefaults.standard.string(forKey: debugURLOverrideKey),
            !override.isEmpty,
            let url = URL(string: override)
        else {
            return nil
        }
        return url
    }
#endif
}

extension CommunityFeature.Path.State: Sendable, Equatable {}
extension CommunityFeature.Path.Action: Sendable {}
