//
//  AnalyticsEvent.swift
//  Presentation
//
//  GA 이벤트 사전(#423). 이름은 사전에 있는 것만 만들 수 있다 — 이후 이슈가 이벤트를 더하고,
//  웹뷰 브리지(#424)는 받은 이름을 `Name(rawValue:)`로 걸러 사전에 없는 이름을 버린다.
//

import Foundation

public struct AnalyticsEvent: Equatable, Sendable {
    public enum Name: String, CaseIterable, Sendable {
        case appOpen = "app_open"
        case sessionRestore = "session_restore"
    }

    /// 어디서 기록했나. 클라이언트가 모든 이벤트에 `surface` 꼬리표로 붙인다.
    public enum Surface: String, Sendable {
        case native
        case webview
    }

    public enum Value: Equatable, Sendable {
        case string(String)
        case int(Int)
    }

    public let name: Name
    public let parameters: [String: Value]
    public let surface: Surface

    public init(_ name: Name, parameters: [String: Value] = [:], surface: Surface = .native) {
        self.name = name
        self.parameters = parameters
        self.surface = surface
    }
}

// MARK: - 사전 이벤트

extension AnalyticsEvent {
    /// `app_open`의 `from` — 앱이 열린 입구(사전 "from 값").
    public enum OpenSource: String, Sendable {
        case icon
        case push
        /// 유니버설 링크
        case deeplink
        /// 앱 주소(`bjjossapp://`)
        case scheme
        /// 공유 링크(`utm_medium=share`)
        case shareLink = "share_link"
    }

    /// `app_open`의 `app_state` — 앱이 꺼져 있다 켜졌나(cold), 백그라운드에서 돌아왔나(warm).
    public enum AppState: String, Sendable {
        case cold
        case warm
    }

    /// `session_restore`의 `result` — 스플래시 자동 로그인 결과.
    public enum SessionRestoreResult: String, Sendable {
        /// 저장된 로그인으로 들어감
        case restored = "ok"
        /// 저장된 로그인이 없음
        case guest
        /// 저장된 로그인이 만료됐거나 서버에 닿지 못함
        case fail
        /// 자동 로그인을 기다리다 시간 초과
        case timeout
    }

    public static func appOpen(from source: OpenSource, appState: AppState) -> Self {
        Self(.appOpen, parameters: ["from": .string(source.rawValue), "app_state": .string(appState.rawValue)])
    }

    public static func sessionRestore(_ result: SessionRestoreResult) -> Self {
        Self(.sessionRestore, parameters: ["result": .string(result.rawValue)])
    }
}

// MARK: - 사용자 속성

/// GA 사용자 속성(사전 "사용자 속성"). `signup_week`는 서버 값이 생기면 더한다.
public enum AnalyticsUserProperty: String, CaseIterable, Sendable {
    case accountType = "account_type"
    case belt
    case stripes
    case coachRole = "coach_role"
    case loginMethod = "login_method"
    case pushEnabled = "push_enabled"
    case hasCompRecord = "has_comp_record"
    case hasGym = "has_gym"

    /// 서버 계정 구분(MEMBER · OPERATOR · INTERNAL) → `account_type` 값(member · operator · internal).
    /// 사전에 없는 값은 nil — 모르는 값을 GA에 새 분류로 쌓지 않는다.
    public static func accountTypeValue(_ serverValue: String?) -> String? {
        guard let value = serverValue?.lowercased(), ["member", "operator", "internal"].contains(value) else { return nil }
        return value
    }
}

// MARK: - 사전 검사

/// GA가 조용히 버리거나 잘라 내는 값을 보내기 전에 거른다. 위반한 기록은 보내지 않는다.
public enum AnalyticsValidation {
    static let maxNameLength = 40
    /// `surface`를 포함한 꼬리표 수
    static let maxParameterCount = 25
    static let maxParameterValueLength = 100
    static let maxUserPropertyNameLength = 24
    static let maxUserPropertyValueLength = 36
    static let reservedPrefixes = ["firebase_", "google_", "ga_"]
    static let surfaceKey = "surface"

    /// 위반 내용. 비어 있으면 보낼 수 있다.
    public static func violations(of event: AnalyticsEvent) -> [String] {
        var problems = nameViolations(event.name.rawValue, maxLength: maxNameLength)
        if event.parameters.count + 1 > maxParameterCount {
            problems.append("꼬리표 \(event.parameters.count + 1)개 > \(maxParameterCount)")
        }
        for (key, value) in event.parameters.sorted(by: { $0.key < $1.key }) {
            if key == surfaceKey {
                problems.append("'\(surfaceKey)'는 클라이언트가 붙인다")
            }
            problems += nameViolations(key, maxLength: maxNameLength)
            if case let .string(text) = value, text.count > maxParameterValueLength {
                problems.append("'\(key)' 값 \(text.count)자 > \(maxParameterValueLength)")
            }
        }
        return problems
    }

    public static func violations(of property: AnalyticsUserProperty, value: String?) -> [String] {
        var problems = nameViolations(property.rawValue, maxLength: maxUserPropertyNameLength)
        if let value, value.count > maxUserPropertyValueLength {
            problems.append("'\(property.rawValue)' 값 \(value.count)자 > \(maxUserPropertyValueLength)")
        }
        return problems
    }

    /// 영문자로 시작하고 영문자 · 숫자 · 밑줄만, 길이 제한, 예약 접두어 금지.
    private static func nameViolations(_ name: String, maxLength: Int) -> [String] {
        var problems: [String] = []
        if name.isEmpty || name.count > maxLength {
            problems.append("'\(name)' 길이 \(name.count)자 (1~\(maxLength))")
        }
        let isAllowed = name.first.map { $0.isASCII && $0.isLetter } == true
            && name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
        if !isAllowed {
            problems.append("'\(name)' 영문자로 시작하는 영문 · 숫자 · 밑줄만")
        }
        if let prefix = reservedPrefixes.first(where: { name.hasPrefix($0) }) {
            problems.append("'\(name)' 금지 접두어 \(prefix)")
        }
        return problems
    }
}
