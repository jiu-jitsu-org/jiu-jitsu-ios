//
//  WebBridgeMessage.swift
//  Presentation
//
//  네이티브 ↔ 웹뷰 통신 계약(Contract)의 단일 출처(Single Source of Truth).
//  FE의 `src/shared/lib/native-bridge/messages.ts`와 1:1로 대응한다.
//
//  - 웹 → 네이티브 (Outbound, 웹 기준): `window.webkit.messageHandlers.AppBridge.postMessage(msg)`
//  - 네이티브 → 웹 (Inbound, 웹 기준): `window.WebBridge.receive(jsonString)`
//
//  메시지 `type`은 양 플랫폼(Swift/Kotlin/TS)에서 enum rawValue로 그대로 쓰고
//  로그에서 grep 하기 쉽도록 UPPER_SNAKE_CASE 문자열로 고정한다.
//

import Foundation
import CoreKit

// MARK: - Bridge Source (로그 식별)

/// 브릿지 트래픽이 어느 웹뷰의 것인지 구분하는 출처 라벨.
/// 리스트·상세(서브뷰)가 각자 WKWebView를 갖고 같은 메시지를 주고받아, 로그만 보면
/// "어느 웹뷰가 갱신을 요청했고 어느 웹뷰로 응답이 갔는지"를 알 수 없었다(#26). 그 추적용이다.
enum WebBridgeSource: Equatable, Sendable {
    case list
    case detail(URL)

    var label: String {
        switch self {
        case .list:
            return "list"
        case let .detail(url):
            // 토큰·쿼리가 섞이지 않도록 경로만 남긴다.
            return "detail\(url.path)"
        }
    }
}

// MARK: - Bridge Naming / Schema

enum WebBridge {
    /// 웹 → 네이티브 수신구. `WKUserContentController.add(_:name:)`에 등록하는 핸들러 이름.
    /// FE/Android와 공유하는 고정 계약이므로 변경 시 양 플랫폼 동시 합의가 필요하다.
    static let appBridgeHandlerName = "AppBridge"

    // MARK: - Logging

    /// 브릿지 트래픽 전용 로그 카테고리. 네트워크 로그처럼 한곳에 모여 보이도록 분리한다.
    /// (`static let`은 Swift 6 strict concurrency에서 Sendable 제약이 걸리므로 함수로 제공)
    private static func logCategory() -> Log.Category {
        .custom(label: "Bridge", emoji: "🌉")
    }

    /// 웹 → 네이티브 수신 원본(raw)을 파싱 전에 구조 그대로 기록한다.
    /// `type` 누락·payload 형태 불일치 같은 계약 위반도 로그에 남도록, 해석된 요약(`logInbound`)과 별개로 호출한다.
    static func logInboundRaw(_ body: Any, source: WebBridgeSource) {
        Log.trace("⬇︎ IN  [\(source.label)] [raw] \(describeBody(body))", category: logCategory(), level: .info)
    }

    /// 웹 → 네이티브 수신 메시지(해석 결과)를 한 줄로 기록한다.
    static func logInbound(_ message: WebBridgeInboundMessage, source: WebBridgeSource) {
        Log.trace("⬇︎ IN  [\(source.label)] \(message.logSummary)", category: logCategory(), level: .info)
    }

    /// 메시지 송수신이 아닌 브릿지 처리 판단(만료 토큰 주입 보류 등)을 같은 카테고리에 남긴다.
    static func logEvent(_ message: String, source: WebBridgeSource) {
        Log.trace("··  [\(source.label)] \(message)", category: logCategory(), level: .info)
    }

    /// raw body를 사람이 읽기 좋은 형태로 기술한다.
    /// 웹이 보낸 봉투가 객체(`postMessage(obj)`)인지 JSON 문자열인지, 그리고 그 내용 전체를 노출한다.
    private static func describeBody(_ body: Any) -> String {
        if body is [String: Any] {
            return prettyJSON(from: body).map { "(object)\n\($0)" } ?? "(object) \(body)"
        }
        if let string = body as? String {
            if let json = prettyJSON(from: body) {
                return "(json-string)\n\(json)"
            }
            return "(string) \(string)"
        }
        return "(\(Swift.type(of: body))) \(body)"
    }

    /// 딕셔너리/JSON 문자열을 정렬·들여쓰기된 JSON 문자열로 변환한다(실패 시 nil).
    private static func prettyJSON(from body: Any) -> String? {
        let object: Any
        if let dictionary = body as? [String: Any] {
            object = dictionary
        } else if
            let jsonString = body as? String,
            let data = jsonString.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: data) {
            object = parsed
        } else {
            return nil
        }
        guard
            JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }

    /// 네이티브 → 웹 전송 메시지를 한 줄로 기록한다.
    static func logOutbound(_ message: WebBridgeOutboundMessage, source: WebBridgeSource) {
        Log.trace("⬆︎ OUT [\(source.label)] \(message.logSummary)", category: logCategory(), level: .info)
    }

    /// 로그에 토큰 원문을 남기지 않도록 마스킹한다(앞 8자 + 길이만 노출).
    static func maskToken(_ token: String) -> String {
        guard token.count > 8 else { return "***(len=\(token.count))" }
        return "\(token.prefix(8))…(len=\(token.count))"
    }
}

// MARK: - Log Summaries (가독성용 한 줄 요약)

private extension WebBridgeInboundMessage {
    var logSummary: String {
        switch self {
        case .webViewReady:
            return "WEBVIEW_READY"
        case let .authLoginPrompt(reason):
            return "AUTH_LOGIN_PROMPT  reason=\(reason ?? "-")"
        case let .authLoginModal(reason):
            return "AUTH_LOGIN_MODAL  reason=\(reason ?? "-")"
        case .authLogoutRequest:
            return "AUTH_LOGOUT_REQUEST"
        case .authTokenRefresh:
            return "AUTH_TOKEN_REFRESH_REQUEST"
        case let .openSubview(payload):
            return "OPEN_SUBVIEW  url=\(payload.url) presentation=\(payload.presentation.rawValue) title=\(payload.title ?? "-")"
        case .closeSubview:
            return "CLOSE_SUBVIEW  (payload 없음)"
        case let .backGuard(enabled):
            return "BACK_GUARD  enabled=\(enabled)"
        case let .showConfirmDialog(payload):
            return "SHOW_CONFIRM_DIALOG  reqId=\(payload.requestId) destructive=\(payload.destructive)"
        case let .showSelectSheet(payload):
            return "SHOW_SELECT_SHEET  reqId=\(payload.requestId) options=\(payload.options.count)"
        case let .unknown(type):
            return "\(type)  (unsupported)"
        }
    }
}

private extension WebBridgeOutboundMessage {
    var logSummary: String {
        switch self {
        case let .authLoginSuccess(accessToken):
            return "AUTH_LOGIN_SUCCESS  accessToken=\(WebBridge.maskToken(accessToken))"
        case .authLoginCancelled:
            return "AUTH_LOGIN_CANCELLED"
        case .authSessionExpired:
            return "AUTH_SESSION_EXPIRED"
        case .authLogout:
            return "AUTH_LOGOUT"
        case .backPressed:
            return "BACK_PRESSED"
        case let .confirmDialogResult(requestId, outcome):
            return "CONFIRM_DIALOG_RESULT  reqId=\(requestId) result=\(outcome.rawValue)"
        case let .selectSheetResult(requestId, outcome):
            switch outcome {
            case let .submit(value, customText):
                return "SELECT_SHEET_RESULT  reqId=\(requestId) result=submit value=\(value) custom=\(customText != nil)"
            case .dismiss:
                return "SELECT_SHEET_RESULT  reqId=\(requestId) result=dismiss"
            }
        }
    }
}

// MARK: - Inbound (웹 → 네이티브)

/// 웹뷰가 `AppBridge`로 보내오는 메시지. 알 수 없는 타입은 `.unknown`으로 흡수해
/// 계약이 한쪽만 먼저 배포돼도 크래시 없이 무시할 수 있게 한다.
///
/// `CommunityFeature.Action`(public)의 연관값으로 노출되므로 public이다.
public enum WebBridgeInboundMessage: Equatable, Sendable {
    /// 웹뷰가 메시지 수신 준비를 마쳤음을 알리는 핸드셰이크.
    case webViewReady
    /// 비로그인 행위 시도 → "로그인이 필요해요" 안내 알럿 노출 요청.
    /// 사용자가 알럿에서 [로그인]을 선택해야 로그인 모달로 이어진다(소프트 유도).
    case authLoginPrompt(reason: String?)
    /// 비로그인 행위 시도 → 로그인 모달을 즉시 노출 요청(다이렉트).
    case authLoginModal(reason: String?)
    /// 웹 주도 로그아웃 요청(선택).
    case authLogoutRequest
    /// 웹뷰가 자기 access token 만료를 감지 → 네이티브에 토큰 갱신을 위임한다(하이브리드 토큰 소유권은 네이티브).
    /// 네이티브는 저장된 refresh 토큰으로 갱신 후 AUTH_LOGIN_SUCCESS(새 토큰) 또는 AUTH_SESSION_EXPIRED로 응답한다.
    case authTokenRefresh
    /// 게시글 상세 등 동일 origin URL을 풀스크린 웹뷰(서브뷰)로 띄우라는 요청.
    case openSubview(OpenSubviewPayload)
    /// 현재 최상단 서브뷰를 닫으라는 요청(웹 헤더의 뒤로가기).
    case closeSubview
    /// 이 화면이 뒤로가기 가드(작성 취소 확인 등)를 갖는지 통지. enabled면 네이티브 back은
    /// 직접 닫지 않고 BACK_PRESSED를 보내 웹이 가드 후 닫게 한다. disabled면 네이티브가 직접 닫는다.
    case backGuard(enabled: Bool)
    /// 확인 알럿 표시 요청. 웹뷰는 자기 프레임 밖(GNB·하단 탭바)을 딤 처리할 수 없어, 풀스크린 딤이
    /// 필요한 표면은 네이티브가 소유한다. 문구는 웹이 payload로 넘기고, 결과(confirm/cancel/dismiss)는
    /// requestId로 짝지어 CONFIRM_DIALOG_RESULT로 회신한다.
    case showConfirmDialog(ConfirmDialogPayload)
    /// 선택 바텀시트 표시 요청(신고 사유 등). 항목을 웹이 넘기므로 사유가 늘어도 앱을 건드리지 않는다.
    /// 결과(submit+선택값 / dismiss)는 requestId로 짝지어 SELECT_SHEET_RESULT로 회신한다.
    case showSelectSheet(SelectSheetPayload)
    /// 계약에 없는 타입(상위 버전/오타 등) — 무시 대상.
    case unknown(type: String)

    private enum MessageType: String {
        case webViewReady = "WEBVIEW_READY"
        case authLoginPrompt = "AUTH_LOGIN_PROMPT"
        case authLoginModal = "AUTH_LOGIN_MODAL"
        case authLogoutRequest = "AUTH_LOGOUT_REQUEST"
        case authTokenRefresh = "AUTH_TOKEN_REFRESH_REQUEST"
        case openSubview = "OPEN_SUBVIEW"
        case closeSubview = "CLOSE_SUBVIEW"
        case backGuard = "BACK_GUARD"
        case showConfirmDialog = "SHOW_CONFIRM_DIALOG"
        case showSelectSheet = "SHOW_SELECT_SHEET"
    }

    /// `WKScriptMessage.body`를 파싱한다.
    /// iOS는 `postMessage(객체)` 형태라 보통 `[String: Any]`(NSDictionary)로 들어오지만,
    /// 플랫폼/구현차로 JSON 문자열이 올 수도 있어 둘 다 허용한다.
    static func decode(from body: Any) -> WebBridgeInboundMessage? {
        guard let object = normalizedObject(from: body) else {
            Log.trace("WebBridge inbound 파싱 실패: \(body)", category: .network, level: .error)
            return nil
        }
        guard let rawType = object["type"] as? String else {
            Log.trace("WebBridge inbound에 type 누락", category: .network, level: .error)
            return nil
        }

        let payload = object["payload"] as? [String: Any]

        switch MessageType(rawValue: rawType) {
        case .webViewReady:
            return .webViewReady
        case .authLoginPrompt:
            return .authLoginPrompt(reason: payload?["reason"] as? String)
        case .authLoginModal:
            return .authLoginModal(reason: payload?["reason"] as? String)
        case .authLogoutRequest:
            return .authLogoutRequest
        case .authTokenRefresh:
            return .authTokenRefresh
        case .openSubview:
            // url은 필수. 빈 값/누락이면 띄울 대상이 없으므로 무시한다(동일 origin 검사는 Feature가 수행).
            guard let urlString = payload?["url"] as? String, !urlString.isEmpty else {
                Log.trace("OPEN_SUBVIEW payload url 누락/빈값", category: .network, level: .error)
                return nil
            }
            let presentation = (payload?["presentation"] as? String)
                .flatMap(OpenSubviewPayload.Presentation.init(rawValue:)) ?? .push
            return .openSubview(
                OpenSubviewPayload(
                    url: urlString,
                    title: payload?["title"] as? String,
                    presentation: presentation
                )
            )
        case .closeSubview:
            return .closeSubview
        case .backGuard:
            return .backGuard(enabled: payload?["enabled"] as? Bool ?? false)
        case .showConfirmDialog:
            // requestId·title·confirmText는 필수. 하나라도 없으면 회신할 대상/문구가 없어 무시한다
            // (웹은 무응답을 타임아웃 후 cancel로 간주하므로 화면이 멈추지 않는다).
            guard
                let requestId = payload?["requestId"] as? String, !requestId.isEmpty,
                let title = payload?["title"] as? String,
                let confirmText = payload?["confirmText"] as? String
            else {
                Log.trace("SHOW_CONFIRM_DIALOG payload 필수 필드 누락", category: .network, level: .error)
                return nil
            }
            return .showConfirmDialog(
                ConfirmDialogPayload(
                    requestId: requestId,
                    title: title,
                    message: payload?["message"] as? String,
                    confirmText: confirmText,
                    cancelText: payload?["cancelText"] as? String,
                    destructive: payload?["destructive"] as? Bool ?? false,
                    dismissOnOutsideTap: payload?["dismissOnOutsideTap"] as? Bool ?? true
                )
            )
        case .showSelectSheet:
            guard
                let requestId = payload?["requestId"] as? String, !requestId.isEmpty,
                let title = payload?["title"] as? String,
                let submitText = payload?["submitText"] as? String
            else {
                Log.trace("SHOW_SELECT_SHEET payload 필수 필드 누락", category: .network, level: .error)
                return nil
            }
            // value/label이 없는 항목은 선택·전송이 불가능하므로 건너뛴다.
            let options: [SelectSheetPayload.Option] = (payload?["options"] as? [[String: Any]] ?? [])
                .compactMap { raw in
                    guard
                        let value = raw["value"] as? String,
                        let label = raw["label"] as? String
                    else { return nil }
                    return SelectSheetPayload.Option(
                        value: value,
                        label: label,
                        allowsCustomText: raw["allowsCustomText"] as? Bool ?? false
                    )
                }
            return .showSelectSheet(
                SelectSheetPayload(
                    requestId: requestId,
                    title: title,
                    message: payload?["message"] as? String,
                    options: options,
                    customTextPlaceholder: payload?["customTextPlaceholder"] as? String,
                    submitText: submitText
                )
            )
        case .none:
            return .unknown(type: rawType)
        }
    }

    private static func normalizedObject(from body: Any) -> [String: Any]? {
        if let dictionary = body as? [String: Any] {
            return dictionary
        }
        if
            let jsonString = body as? String,
            let data = jsonString.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return object
        }
        return nil
    }
}

// MARK: - OPEN_SUBVIEW Payload

/// `OPEN_SUBVIEW` 페이로드. 게시글 상세 등 동일 origin URL을 풀스크린 웹뷰로 여는 데 필요한 정보.
/// `CommunityFeature.Action`의 연관값으로 노출되므로 public이다.
public struct OpenSubviewPayload: Equatable, Sendable {
    /// 서브뷰 표시 방식. 기본은 push(네비게이션 스택), modal은 fullScreenCover.
    public enum Presentation: String, Sendable {
        case push
        case modal
    }

    /// 동일 origin 절대경로(예: https://.../community/123).
    public let url: String
    /// 웹 헤더 렌더 전 임시 제목(선택).
    public let title: String?
    /// push(기본) | modal.
    public let presentation: Presentation

    public init(url: String, title: String?, presentation: Presentation) {
        self.url = url
        self.title = title
        self.presentation = presentation
    }
}

// MARK: - Dialog Payloads (SHOW_CONFIRM_DIALOG / SHOW_SELECT_SHEET)

/// `SHOW_CONFIRM_DIALOG` 페이로드 — 네이티브가 그릴 확인 알럿. 문구·라벨은 전부 웹이 채운다.
/// `WebBridgeInboundMessage`(public)의 연관값으로 노출되므로 public이다.
public struct ConfirmDialogPayload: Equatable, Sendable {
    /// 웹이 발급하는 요청 식별자 — 결과 회신을 이 값으로 매칭한다.
    public let requestId: String
    public let title: String
    public let message: String?
    public let confirmText: String
    /// 미지정 시 네이티브가 "취소"를 쓴다.
    public let cancelText: String?
    /// true면 확인 버튼을 위험색(destructive)으로 그린다.
    public let destructive: Bool
    /// 딤 바깥 탭으로 닫을 수 있는지(미지정 시 true). 바깥 탭 닫힘은 dismiss로 회신한다.
    public let dismissOnOutsideTap: Bool

    public init(
        requestId: String,
        title: String,
        message: String?,
        confirmText: String,
        cancelText: String?,
        destructive: Bool,
        dismissOnOutsideTap: Bool
    ) {
        self.requestId = requestId
        self.title = title
        self.message = message
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.destructive = destructive
        self.dismissOnOutsideTap = dismissOnOutsideTap
    }
}

/// `SHOW_SELECT_SHEET` 페이로드 — 네이티브가 그릴 선택 바텀시트(신고 사유 등).
public struct SelectSheetPayload: Equatable, Sendable {
    /// 선택 항목. value는 API로 보낼 코드, label은 사용자에게 보일 문구.
    public struct Option: Equatable, Sendable {
        public let value: String
        public let label: String
        /// 고르면 자유 입력 필드를 함께 노출한다(신고 사유의 "기타" 등).
        public let allowsCustomText: Bool

        public init(value: String, label: String, allowsCustomText: Bool) {
            self.value = value
            self.label = label
            self.allowsCustomText = allowsCustomText
        }
    }

    public let requestId: String
    public let title: String
    /// 제목 아래 보조 설명(선택).
    public let message: String?
    public let options: [Option]
    /// 자유 입력 필드의 placeholder(선택).
    public let customTextPlaceholder: String?
    public let submitText: String

    public init(
        requestId: String,
        title: String,
        message: String?,
        options: [Option],
        customTextPlaceholder: String?,
        submitText: String
    ) {
        self.requestId = requestId
        self.title = title
        self.message = message
        self.options = options
        self.customTextPlaceholder = customTextPlaceholder
        self.submitText = submitText
    }
}

// MARK: - Dialog Result Outcomes (네이티브 → 웹 회신 값)

/// 확인 알럿 종료 사유. dismiss = 바깥 탭·시스템 닫힘 등 명시적 버튼이 아닌 닫힘.
public enum ConfirmDialogOutcome: String, Sendable {
    case confirm
    case cancel
    case dismiss
}

/// 선택 시트 종료 결과. submit이면 선택된 항목의 value(+자유 입력)를 함께 싣는다.
public enum SelectSheetOutcome: Equatable, Sendable {
    case submit(value: String, customText: String?)
    case dismiss
}

// MARK: - Origin 검사

/// 서브뷰로 열려는 URL이 호스트 웹뷰와 동일 origin(scheme+host+port)인지 검사한다.
/// 외부 도메인이 네이티브 풀스크린 웹뷰로 열려 세션 쿠키가 새는 것을 막는다.
enum WebOrigin {
    static func isSameOrigin(_ lhs: URL, as rhs: URL) -> Bool {
        guard let lhsKey = originKey(lhs), let rhsKey = originKey(rhs) else { return false }
        return lhsKey == rhsKey
    }

    private static func originKey(_ url: URL) -> String? {
        guard
            let scheme = url.scheme?.lowercased(),
            let host = url.host?.lowercased()
        else { return nil }
        // 포트 미표기는 스킴 기본 포트로 정규화해 `https://h` == `https://h:443`이 되게 한다.
        let port = url.port ?? defaultPort(for: scheme)
        return "\(scheme)://\(host):\(port.map(String.init) ?? "-")"
    }

    private static func defaultPort(for scheme: String) -> Int? {
        switch scheme {
        case "https": return 443
        case "http": return 80
        default: return nil
        }
    }
}

// MARK: - Outbound (네이티브 → 웹)

/// 네이티브가 `window.WebBridge.receive(...)`로 주입하는 메시지.
enum WebBridgeOutboundMessage: Equatable, Sendable {
    /// 로그인 성공, 토큰 전달. (정책: accessToken만 전달, refreshToken은 네이티브 보관)
    case authLoginSuccess(accessToken: String)
    /// 사용자가 로그인 취소 → 대기 중 행위 폐기.
    case authLoginCancelled
    /// 토큰 만료 통지 → 웹 세션 정리.
    case authSessionExpired
    /// 네이티브 주도 로그아웃 → 웹 세션 정리.
    case authLogout
    /// 네이티브 공통 뒤로가기 탭 통지 → 웹이 가드(작성 취소 확인 등) 후 CLOSE_SUBVIEW로 닫는다.
    case backPressed
    /// SHOW_CONFIRM_DIALOG의 결과. requestId로 어느 요청의 답인지 웹이 식별한다.
    case confirmDialogResult(requestId: String, outcome: ConfirmDialogOutcome)
    /// SHOW_SELECT_SHEET의 결과. submit이면 선택값(+자유 입력)을 함께 싣는다.
    case selectSheetResult(requestId: String, outcome: SelectSheetOutcome)

    private var type: String {
        switch self {
        case .authLoginSuccess: return "AUTH_LOGIN_SUCCESS"
        case .authLoginCancelled: return "AUTH_LOGIN_CANCELLED"
        case .authSessionExpired: return "AUTH_SESSION_EXPIRED"
        case .authLogout: return "AUTH_LOGOUT"
        case .backPressed: return "BACK_PRESSED"
        case .confirmDialogResult: return "CONFIRM_DIALOG_RESULT"
        case .selectSheetResult: return "SELECT_SHEET_RESULT"
        }
    }

    private var payload: [String: Any]? {
        switch self {
        case let .authLoginSuccess(accessToken):
            return ["accessToken": accessToken]
        case .authLoginCancelled, .authSessionExpired, .authLogout, .backPressed:
            return nil
        case let .confirmDialogResult(requestId, outcome):
            return ["requestId": requestId, "result": outcome.rawValue]
        case let .selectSheetResult(requestId, outcome):
            switch outcome {
            case let .submit(value, customText):
                var payload: [String: Any] = ["requestId": requestId, "result": "submit", "value": value]
                // 자유 입력은 입력했을 때만 싣는다(계약: customText는 선택 필드).
                if let customText { payload["customText"] = customText }
                return payload
            case .dismiss:
                return ["requestId": requestId, "result": "dismiss"]
            }
        }
    }

    /// `window.WebBridge.receive(<jsonString>)`를 호출하는 JS 코드를 생성한다.
    /// 반환값을 `evaluateJavaScript`에 그대로 넘기면 된다. 직렬화 실패 시 nil.
    func makeJavaScript() -> String? {
        guard let envelopeJSON = makeEnvelopeJSON() else { return nil }

        // receive()의 인자는 "JSON 문자열"이다. JS 문자열 리터럴로 안전하게 내장하기 위해
        // JSON 문자열을 한 번 더 인코딩한다(따옴표/역슬래시/개행 등 자동 이스케이프).
        guard
            let literalData = try? JSONEncoder().encode(envelopeJSON),
            let literal = String(data: literalData, encoding: .utf8)
        else {
            Log.trace("WebBridge outbound JS 리터럴 생성 실패: \(type)", category: .network, level: .error)
            return nil
        }

        // WebBridge가 아직 정의되지 않았을 가능성을 방어한다(레이스/조기 호출).
        return "if (window.WebBridge && window.WebBridge.receive) { window.WebBridge.receive(\(literal)); }"
    }

    private func makeEnvelopeJSON() -> String? {
        var envelope: [String: Any] = ["type": type]
        if let payload { envelope["payload"] = payload }

        guard
            let data = try? JSONSerialization.data(withJSONObject: envelope),
            let json = String(data: data, encoding: .utf8)
        else {
            Log.trace("WebBridge envelope 직렬화 실패: \(type)", category: .network, level: .error)
            return nil
        }
        return json
    }
}

// MARK: - Outbound Envelope (전달 큐 원소)

/// View가 `evaluateJavaScript`로 실제 전달했는지 추적하기 위해 식별자를 부여한 봉투.
/// 같은 메시지가 State 재평가로 중복 전송되지 않도록 id 기준으로 관리한다.
struct WebBridgeOutboundEnvelope: Equatable, Sendable, Identifiable {
    let id: UUID
    let message: WebBridgeOutboundMessage
}
