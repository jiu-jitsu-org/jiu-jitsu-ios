//
//  WebLoadReport.swift
//  Presentation
//
//  웹뷰 로드 결과를 화면(Feature)으로 올리는 값(#431). 웹뷰 안(Coordinator)만 실패 이유와 걸린 시간을 알아,
//  오류 화면을 띄우는 Feature가 이 값으로 error_shown · screen_load를 남긴다.
//

import Foundation

/// 웹 문서 로드 실패. `code`는 사전 `error_code` 값이다(문구 · 주소는 싣지 않는다).
public struct WebLoadFailure: Equatable, Sendable {
    public let code: String
    public let isTimeout: Bool

    static let timeoutCode = "TIMEOUT"
    /// 웹 프로세스가 죽어 오류 화면으로 돌림(#352).
    static let processTerminated = WebLoadFailure(code: "PROCESS_TERMINATED", isTimeout: false)

    init(code: String, isTimeout: Bool) {
        self.code = code
        self.isTimeout = isTimeout
    }

    /// HTTP 4xx · 5xx는 `HTTP_502`처럼, 문서 요청 시간 초과는 `TIMEOUT`, 그 밖은 오류 코드(`-1009` 등).
    init(error: Error) {
        if let http = error as? WebHTTPStatusError {
            self.init(statusCode: http.statusCode)
            return
        }
        let error = error as NSError
        if error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut {
            self.init(code: Self.timeoutCode, isTimeout: true)
        } else {
            self.init(code: String(error.code), isTimeout: false)
        }
    }

    init(statusCode: Int) {
        self.init(code: "HTTP_\(statusCode)", isTimeout: false)
    }
}

/// 웹 메인 문서가 4xx · 5xx로 와서 막음. WKWebView는 이걸 정상 로드로 여겨 실패 알림을 따로 주지 않는다.
struct WebHTTPStatusError: Error {
    let statusCode: Int
}

/// 웹뷰를 연 뒤 화면이 손 닿는 상태(PAGE_READY)가 되기까지, 또는 그 전에 실패하기까지 걸린 시간.
public struct WebScreenLoad: Equatable, Sendable {
    public let result: AnalyticsEvent.ScreenLoadResult
    public let milliseconds: Int
}
