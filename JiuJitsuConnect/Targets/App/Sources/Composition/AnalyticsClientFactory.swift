//
//  AnalyticsClientFactory.swift
//  App
//
//  TCA `AnalyticsClient`의 live 인스턴스(Firebase Analytics, #423).
//  광고 식별자를 쓰지 않는 FirebaseAnalyticsCore만 링크한다. 모듈 이름은 FirebaseAnalytics로 같다.
//

import CoreKit
import FirebaseAnalytics
import Foundation
import Presentation

enum AnalyticsClientFactory {

    /// 설정 "이용 통계". Firebase도 값을 기억하지만, 화면에 보일 값과 실행 때 반영할 값을 한곳에서 읽으려고 따로 둔다.
    private static let collectionEnabledKey = "jj.analytics.collection_enabled"

    /// `FirebaseApp.configure()` 직후 부른다. 꺼 둔 사람은 다음 실행에도 꺼진 채로 시작한다.
    static func applyStoredCollectionSetting() {
        Analytics.setAnalyticsCollectionEnabled(isCollectionEnabled(UserDefaults.standard))
    }

    static func make() -> AnalyticsClient {
        nonisolated(unsafe) let defaults = UserDefaults.standard

        return AnalyticsClient(
            logEvent: { event in
                // 끈 동안 웹뷰 브리지에서 온 기록도 여기서 버린다(#424가 같은 클라이언트를 쓴다).
                guard isCollectionEnabled(defaults) else { return }
                let problems = AnalyticsValidation.violations(of: event)
                guard problems.isEmpty else {
                    // 웹뷰에서 온 기록은 외부 입력이라 Debug에서도 멈추지 않고 버리기만 한다.
                    report(
                        "이벤트 \(event.name.rawValue)(\(event.surface.rawValue)) 버림: \(problems.joined(separator: ", "))",
                        stopsInDebug: event.surface == .native
                    )
                    return
                }
                var parameters: [String: Any] = ["surface": event.surface.rawValue]
                for (key, value) in event.parameters {
                    switch value {
                    case let .string(text): parameters[key] = text
                    case let .int(number): parameters[key] = number
                    }
                }
                Log.trace("[Analytics] \(event.name.rawValue) \(parameters)", category: .debug, level: .info)
                Analytics.logEvent(event.name.rawValue, parameters: parameters)
            },
            setUserProperty: { value, property in
                let problems = AnalyticsValidation.violations(of: property, value: value)
                guard problems.isEmpty else {
                    report("사용자 속성 \(property.rawValue) 버림: \(problems.joined(separator: ", "))", stopsInDebug: true)
                    return
                }
                Log.trace("[Analytics] user property \(property.rawValue)=\(value ?? "nil")", category: .debug, level: .info)
                Analytics.setUserProperty(value, forName: property.rawValue)
            },
            setUserID: { userID in
                Log.trace("[Analytics] user id \(userID == nil ? "nil" : "set")", category: .debug, level: .info)
                Analytics.setUserID(userID)
            },
            isCollectionEnabled: {
                isCollectionEnabled(defaults)
            },
            setCollectionEnabled: { isEnabled in
                defaults.set(isEnabled, forKey: collectionEnabledKey)
                Analytics.setAnalyticsCollectionEnabled(isEnabled)
            },
            resetAnalyticsData: {
                Analytics.resetAnalyticsData()
            },
            handleOpen: { url in
                guard isCollectionEnabled(defaults) else { return }
                Analytics.handleOpen(url)
            }
        )
    }

    private static func isCollectionEnabled(_ defaults: UserDefaults) -> Bool {
        defaults.object(forKey: collectionEnabledKey) as? Bool ?? true
    }

    /// 앱 코드의 사전 위반은 실수라 Debug에서는 바로 멈춰 알린다. 그 밖에는 기록만 버린다.
    private static func report(_ message: String, stopsInDebug: Bool) {
        Log.trace("[Analytics] \(message)", category: .debug, level: .error)
        #if DEBUG
        if stopsInDebug {
            assertionFailure(message)
        }
        #endif
    }
}
