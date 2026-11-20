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

    static let timeoutCode = "TIMEOUT"
    /// 웹 프로세스가 죽어 오류 화면으로 돌림(#352).
    static let processTerminated = WebLoadFailure(code: "PROCESS_TERMINATED")

    init(code: String) {
        self.code = code
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
            self.init(code: String(error.code))
        }
    }

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

// MARK: - 화면 속도 측정 (#431)

extension BridgeWebView.Coordinator {
    /// 문서는 다 받았는데 이만큼 지나도 PAGE_READY가 없으면 재지 않는다 — 원래 안 보내는 화면(밸런스 상세 등)이나
    /// 웹 오류 화면이다. 남겨 두면 나중에 웹의 다시 시도가 보낸 PAGE_READY가 오래 머문 시간까지 가져간다.
    static let pageReadyWaitAfterFinish: Duration = .seconds(10)

    func reportScreenLoad(_ result: AnalyticsEvent.ScreenLoadResult) {
        guard let startedAt = screenLoadStartedAt else { return }
        screenLoadStartedAt = nil
        let endedAt = replayingEventAt ?? .now
        let milliseconds = max(0, Int(((endedAt - startedAt) / .milliseconds(1)).rounded()))
        onScreenLoadMeasured?(WebScreenLoad(result: result, milliseconds: milliseconds))
    }

    func discardScreenLoadIfPageNeverReady() {
        guard let startedAt = screenLoadStartedAt else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.pageReadyWaitAfterFinish)
            guard let self, self.screenLoadStartedAt == startedAt else { return }
            self.screenLoadStartedAt = nil
        }
    }
}
