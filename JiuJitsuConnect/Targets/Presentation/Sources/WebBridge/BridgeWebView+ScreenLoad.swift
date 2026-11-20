//
//  BridgeWebView+ScreenLoad.swift
//  Presentation
//
//  BridgeWebView 코디네이터의 화면 속도 측정(screen_load, #431). 파일 길이 때문에 BridgeWebView.swift에서 나눴다.
//

import Foundation

extension BridgeWebView.Coordinator {
    /// 문서는 다 받았는데 이만큼 지나도 PAGE_READY가 없으면 재지 않는다 — 원래 안 보내는 화면(밸런스 상세 등)이나
    /// 웹 오류 화면이다. 남겨 두면 나중에 웹의 다시 시도가 보낸 PAGE_READY가 오래 머문 시간까지 가져간다.
    static let pageReadyWaitAfterFinish: Duration = .seconds(10)

    /// 지금 이벤트가 실제로 온 시각. 미리 불러 둔 홈이 받아 둔 이벤트를 다시 보내는 중이면 그때 받은 시각이다.
    private var eventTime: ContinuousClock.Instant { replayingEventAt ?? .now }

    /// 재던 로드의 결과를 올린다. 문서를 받은 뒤 기다림이 지난 결과는 버린다.
    func reportScreenLoad(_ result: AnalyticsEvent.ScreenLoadResult) {
        guard let startedAt = screenLoadStartedAt else { return }
        let endedAt = eventTime
        let isPastDeadline = screenLoadDeadline.map { endedAt > $0 } ?? false
        screenLoadStartedAt = nil
        guard !isPastDeadline else { return }
        let milliseconds = max(0, Int(((endedAt - startedAt) / .milliseconds(1)).rounded()))
        onScreenLoadMeasured?(WebScreenLoad(result: result, milliseconds: milliseconds))
    }

    /// 문서를 다 받음(didFinish). 처음 받은 때부터 기다림을 센다 — 웹 안의 다음 문서가 기한을 늘리지 않게.
    func markScreenLoadDocumentFinished() {
        guard screenLoadStartedAt != nil, screenLoadDeadline == nil else { return }
        screenLoadDeadline = eventTime + Self.pageReadyWaitAfterFinish
    }
}
