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
    /// 기기가 망에 닿지 못해 실패함(#396). 덮개가 '연결이 불안정해요'를 보이고, 연결이 돌아오면 한 번 저절로 다시 불러온다.
    let isConnectionProblem: Bool

    static let timeoutCode = "TIMEOUT"
    /// 웹 프로세스가 죽어 오류 화면으로 돌림(#352).
    static let processTerminated = WebLoadFailure(code: "PROCESS_TERMINATED")
    /// 첫 문서의 리다이렉트를 이동 정책이 막아 띄울 문서가 없음. WebKit이 취소(-999)로 알려도 새 로드에 밀린 취소와 다르다.
    static let blockedByPolicy = WebLoadFailure(code: "POLICY_BLOCKED")

    init(code: String, isConnectionProblem: Bool = false) {
        self.code = code
        self.isConnectionProblem = isConnectionProblem
    }

    var isTimeout: Bool { code == Self.timeoutCode }

    /// 새 로드가 진행 중이던 로드를 갈아 끼워 취소됨(같은 글 푸시 · 링크로 다시 열기 등). 사용자가 본 오류가 아니다.
    var isCancelled: Bool { code == String(NSURLErrorCancelled) }

    /// HTTP 4xx · 5xx는 `HTTP_502`처럼, 문서 요청 시간 초과는 `TIMEOUT`, 그 밖은 오류 코드(`-1009` 등).
    init(error: Error) {
        if let http = error as? WebHTTPStatusError {
            self.init(statusCode: http.statusCode)
            return
        }
        let error = error as NSError
        if error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut {
            self.init(code: Self.timeoutCode)
        } else {
            let isConnectionProblem = error.domain == NSURLErrorDomain && Self.connectionProblemCodes.contains(error.code)
            self.init(code: String(error.code), isConnectionProblem: isConnectionProblem)
        }
    }

    /// 기기 쪽 망 문제로 서버에 닿지 못한 코드. 연결 없음 · 연결 끊김 · 주소를 못 찾음(DNS) · 데이터 차단 등.
    /// 앱 API(`NetworkService.connectionFailureCodes`)와 달리 `cannotConnectToHost`는 넣지 않는다 — 망은 살아 있고
    /// 웹 서버가 꺼진 경우에 나서, '연결이 불안정해요'가 아니라 지금 문구로 둔다. 시간 초과도 서버가 늦은 것일 수 있어 지금 문구.
    private static let connectionProblemCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorCannotFindHost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorDataNotAllowed,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive
    ]

    init(statusCode: Int) {
        self.init(code: "HTTP_\(statusCode)")
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
