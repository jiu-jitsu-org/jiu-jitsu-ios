//
//  WebAnalytics.swift
//  Presentation
//
//  웹뷰가 ANALYTICS_EVENT로 넘긴 기록 처리(#424, #425). 브리지를 받는 목록 · 상세 Feature가 같이 쓴다.
//

import Foundation

enum WebAnalytics {
    /// 화면 기록(screen_view)은 웹이 알린 "이 웹뷰의 지금 화면"이라 기억만 한다 — 그 웹뷰가 맨 위에 실제로 보일 때
    /// 루트 분석 리듀서가 기록한다(#425). 다시 불러와도 지우지 않는다(웹은 같은 화면이면 다시 알리지 않음).
    /// 그 밖의 기록은 바로 남긴다.
    static func receive(_ event: AnalyticsEvent, lastScreen: inout AnalyticsEvent?, client: AnalyticsClient) {
        if event.name == .screenView {
            lastScreen = event
        } else {
            client.logEvent(event)
        }
    }
}
