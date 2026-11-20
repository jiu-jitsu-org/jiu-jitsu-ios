//
//  WebAnalytics.swift
//  Presentation
//
//  웹뷰가 ANALYTICS_EVENT로 넘긴 기록 처리(#424, #425). 브리지를 받는 목록 · 상세 Feature가 같이 쓴다.
//

import CoreKit
import Domain
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
            if event.name == .beltUpdate {
                updateBeltProperties(from: event, client: client)
            }
        }
    }

    /// 웹의 띠 묻기 시트가 띠를 저장함(#460). 웹은 사용자 속성을 정하지 않으므로 앱이 바로 맞춘다.
    /// 루트의 `sentProfileProperties`는 맞추지 않는다 — MY는 탭에 다시 들어올 때까지 띠 없는 옛 프로필이라,
    /// 맞춰 두면 루트가 그 옛 값을 바뀐 값으로 보고 다시 보내 속성이 되돌아간다. MY가 새 값을 읽으면 같은 값을 한 번 더 보낼 뿐이다.
    private static func updateBeltProperties(from event: AnalyticsEvent, client: AnalyticsClient) {
        guard case let .string(rawBelt)? = event.parameters["belt"],
              let belt = BeltRank(rawValue: rawBelt.uppercased()),
              case let .int(stripes)? = event.parameters["stripes"],
              (0...4).contains(stripes) else {
            Log.trace("ANALYTICS_EVENT belt_update 띠 값이 달라 사용자 속성은 그대로 둠", category: .network, level: .error)
            return
        }
        client.setUserProperty(belt.rawValue.lowercased(), .belt)
        client.setUserProperty(String(stripes), .stripes)
    }

    /// 웹뷰 로드 시간(screen_load, #431). 웹은 화면 이름(screen_view)을 PAGE_READY 뒤에 알릴 수 있어(WEBVIEW_READY 뒤
    /// 대기열), 아직 이름을 모르는 첫 로드는 이름이 올 때까지 둔다. 실패는 오류 화면이라 이름이 오지 않으니 아는 대로 바로 남긴다.
    static func screenLoadMeasured(
        _ load: WebScreenLoad,
        lastScreen: AnalyticsEvent?,
        pendingLoad: inout WebScreenLoad?,
        client: AnalyticsClient
    ) {
        if load.result == .succeeded, lastScreen == nil {
            pendingLoad = load
            return
        }
        pendingLoad = nil
        client.logEvent(.screenLoad(screenName: lastScreen?.screenName, milliseconds: load.milliseconds, result: load.result))
    }

    /// 화면 이름을 기다리던 screen_load가 있으면 웹이 알린 이 화면 이름으로 남긴다(#431).
    static func logPendingScreenLoad(after event: AnalyticsEvent, pendingLoad: inout WebScreenLoad?, client: AnalyticsClient) {
        guard event.name == .screenView, let load = pendingLoad else { return }
        pendingLoad = nil
        client.logEvent(.screenLoad(screenName: event.screenName, milliseconds: load.milliseconds, result: load.result))
    }

    /// 웹뷰 오류 화면이 뜸(error_shown webview_load, #431).
    static func loadFailed(_ failure: WebLoadFailure, client: AnalyticsClient) {
        guard !failure.isCancelled else { return }
        client.logEvent(.errorShown(.webviewLoad, code: failure.code))
    }
}
