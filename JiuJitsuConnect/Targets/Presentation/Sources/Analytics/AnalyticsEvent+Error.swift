//
//  AnalyticsEvent+Error.swift
//  Presentation
//
//  오류 · 화면 속도 기록(#431). 사용자가 실제로 본 오류와 웹 화면이 뜨는 시간 — 서버 경로를 바꿀 때 전후를 비교한다.
//

import Domain
import Foundation

extension AnalyticsEvent {
    /// 사용자에게 보인 오류 종류(사전 `error_type`).
    public enum ErrorType: String, Sendable {
        case network
        case timeout
        case server
        case notFound = "not_found"
        case forbidden
        case validation
        case upload
        case webviewLoad = "webview_load"
        case unknown
    }

    /// 입력 검사에 걸린 칸(사전 `field` 중 앱이 검사하는 것).
    public enum ErrorField: String, Sendable {
        case nickname
    }

    /// `code`: 서버 오류 코드나 HTTP 상태(문구는 싣지 않는다). 모르면 싣지 않는다.
    public static func errorShown(_ type: ErrorType, code: String? = nil, field: ErrorField? = nil) -> Self {
        Self(.errorShown, parameters: strings([
            "error_type": type.rawValue,
            "error_code": code,
            "field": field?.rawValue
        ]))
    }

    /// 오류를 화면 문구로 바꾼 곳에서 남길 기록. 안내하지 않는 오류(로그인 취소)는 nil — 사용자가 본 오류 문구가 없다.
    /// 세션 만료로 앱이 만료 안내만 띄우는 곳은 부르는 쪽이 거른다(회원 프로필 메뉴 등).
    /// `type`: 무엇을 하다 실패했는지가 종류를 정할 때(사진 업로드는 네트워크 오류여도 upload). 코드는 그대로 싣는다.
    public static func errorShown(for error: Error, as type: ErrorType? = nil) -> Self? {
        guard let domainError = error as? DomainError else { return errorShown(type ?? .unknown) }
        let mapped: (type: ErrorType, code: String?)
        switch domainError {
        case .signInCancelled:
            return nil
        case .networkUnavailable:
            // 앱 네트워크 계층은 연결 끊김과 시간 초과를 같은 오류로 넘긴다.
            mapped = (.network, nil)
        case let .apiError(code, _):
            mapped = (.server, code.rawValue)
        case let .serverError(code, statusCode, _):
            let statusType: ErrorType = switch statusCode {
            case 404: .notFound
            case 403: .forbidden
            default: .server
            }
            mapped = (statusType, code ?? statusCode.map(String.init))
        case .accountProblem, .permissionRequired, .missingProfileData,
             .cannotFindRootViewController, .dependencyNotFound, .dataParsingFailed, .unknown:
            mapped = (.unknown, nil)
        }
        return errorShown(type ?? mapped.type, code: mapped.code)
    }

    /// `screen_load`의 결과(사전 `result`).
    public enum ScreenLoadResult: String, Sendable {
        /// PAGE_READY까지 옴
        case succeeded = "ok"
        case fail
        case timeout
    }

    /// `screenName`: 웹이 알린 화면 이름. 모르면(오류 화면 등) 싣지 않는다.
    public static func screenLoad(screenName: String?, milliseconds: Int, result: ScreenLoadResult) -> Self {
        var parameters = strings([
            "screen_name": screenName,
            "load_bucket": loadBucket(milliseconds: milliseconds),
            "result": result.rawValue
        ])
        parameters["load_ms"] = .int(milliseconds)
        return Self(.screenLoad, parameters: parameters)
    }

    /// 사전 `load_bucket`(0-1s · 1-2s · 2-3s · 3-5s · 5s+). 경계값은 위 구간으로 센다.
    static func loadBucket(milliseconds: Int) -> String {
        switch milliseconds {
        case ..<1000: "0-1s"
        case ..<2000: "1-2s"
        case ..<3000: "2-3s"
        case ..<5000: "3-5s"
        default: "5s+"
        }
    }

    /// 화면 기록의 화면 이름. 웹이 알린 screen_view에서 꺼낸다.
    var screenName: String? {
        guard case let .string(name)? = parameters["screen_name"] else { return nil }
        return name
    }
}

extension AnalyticsClient {
    /// 오류를 화면 문구로 바꾼 곳에서 부른다(#431). 안내하지 않는 오류는 남기지 않는다.
    func logErrorShown(_ error: Error, as type: AnalyticsEvent.ErrorType? = nil) {
        guard let event = AnalyticsEvent.errorShown(for: error, as: type) else { return }
        logEvent(event)
    }
}
