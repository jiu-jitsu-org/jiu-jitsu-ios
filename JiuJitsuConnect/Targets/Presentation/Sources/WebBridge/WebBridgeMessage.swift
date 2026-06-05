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

// MARK: - Bridge Naming / Schema

enum WebBridge {
    /// 웹 → 네이티브 수신구. `WKUserContentController.add(_:name:)`에 등록하는 핸들러 이름.
    /// FE/Android와 공유하는 고정 계약이므로 변경 시 양 플랫폼 동시 합의가 필요하다.
    static let appBridgeHandlerName = "AppBridge"

    /// 메시지 봉투(Envelope) 스키마 버전. 계약이 바뀌면 증가시켜 하위호환을 분기한다.
    static let schemaVersion = 1

    // MARK: - Logging

    /// 브릿지 트래픽 전용 로그 카테고리. 네트워크 로그처럼 한곳에 모여 보이도록 분리한다.
    /// (`static let`은 Swift 6 strict concurrency에서 Sendable 제약이 걸리므로 함수로 제공)
    private static func logCategory() -> Log.Category {
        .custom(label: "Bridge", emoji: "🌉")
    }

    /// 웹 → 네이티브 수신 메시지를 한 줄로 기록한다.
    static func logInbound(_ message: WebBridgeInboundMessage) {
        Log.trace("⬇︎ IN  \(message.logSummary)", category: logCategory(), level: .info)
    }

    /// 네이티브 → 웹 전송 메시지를 한 줄로 기록한다.
    static func logOutbound(_ message: WebBridgeOutboundMessage) {
        Log.trace("⬆︎ OUT \(message.logSummary)", category: logCategory(), level: .info)
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
        case let .unknown(type):
            return "\(type)  (unsupported)"
        }
    }
}

private extension WebBridgeOutboundMessage {
    var logSummary: String {
        switch self {
        case let .authLoginSuccess(accessToken, expiresAt):
            return "AUTH_LOGIN_SUCCESS  accessToken=\(WebBridge.maskToken(accessToken)) expiresAt=\(expiresAt.map(String.init) ?? "nil")"
        case .authLoginCancelled:
            return "AUTH_LOGIN_CANCELLED"
        case .authSessionExpired:
            return "AUTH_SESSION_EXPIRED"
        case .authLogout:
            return "AUTH_LOGOUT"
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
    /// 계약에 없는 타입(상위 버전/오타 등) — 무시 대상.
    case unknown(type: String)

    private enum MessageType: String {
        case webViewReady = "WEBVIEW_READY"
        case authLoginPrompt = "AUTH_LOGIN_PROMPT"
        case authLoginModal = "AUTH_LOGIN_MODAL"
        case authLogoutRequest = "AUTH_LOGOUT_REQUEST"
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

// MARK: - Outbound (네이티브 → 웹)

/// 네이티브가 `window.WebBridge.receive(...)`로 주입하는 메시지.
enum WebBridgeOutboundMessage: Equatable, Sendable {
    /// 로그인 성공, 토큰 전달. (정책: accessToken만 전달, refreshToken은 네이티브 보관)
    case authLoginSuccess(accessToken: String, expiresAt: Int?)
    /// 사용자가 로그인 취소 → 대기 중 행위 폐기.
    case authLoginCancelled
    /// 토큰 만료 통지 → 웹 세션 정리.
    case authSessionExpired
    /// 네이티브 주도 로그아웃 → 웹 세션 정리.
    case authLogout

    private var type: String {
        switch self {
        case .authLoginSuccess: return "AUTH_LOGIN_SUCCESS"
        case .authLoginCancelled: return "AUTH_LOGIN_CANCELLED"
        case .authSessionExpired: return "AUTH_SESSION_EXPIRED"
        case .authLogout: return "AUTH_LOGOUT"
        }
    }

    private var payload: [String: Any]? {
        switch self {
        case let .authLoginSuccess(accessToken, expiresAt):
            var payload: [String: Any] = ["accessToken": accessToken]
            // expiresAt은 선택 필드 — 값이 있을 때만 실어 계약 잡음을 줄인다.
            if let expiresAt { payload["expiresAt"] = expiresAt }
            return payload
        case .authLoginCancelled, .authSessionExpired, .authLogout:
            return nil
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
        var envelope: [String: Any] = [
            "type": type,
            "version": WebBridge.schemaVersion
        ]
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
