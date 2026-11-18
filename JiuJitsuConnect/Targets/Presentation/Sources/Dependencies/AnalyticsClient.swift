//
//  AnalyticsClient.swift
//  Presentation
//
//  GA 기록 통로(#423). 실제 구현(Firebase Analytics)은 App 타깃의 AnalyticsClientFactory가 주입한다.
//  기본값은 아무것도 하지 않는다 — 분석은 기능 동작과 무관해, 주입하지 않은 테스트 · 프리뷰에서 막히지 않게 한다.
//

import ComposableArchitecture
import Foundation

public struct AnalyticsClient: Sendable {
    /// 사전 검사를 통과한 이벤트만 `surface`를 붙여 보낸다. 수집이 꺼져 있으면 버린다.
    public var logEvent: @Sendable (AnalyticsEvent) -> Void
    /// nil이면 그 속성을 지운다.
    public var setUserProperty: @Sendable (_ value: String?, _ property: AnalyticsUserProperty) -> Void
    /// 설정 "이용 통계". 기기에 남아 다음 실행에도 유지된다(기본 켬).
    public var isCollectionEnabled: @Sendable () -> Bool
    public var setCollectionEnabled: @Sendable (Bool) -> Void
    /// 탈퇴 때 이 기기의 분석 식별 정보를 지운다.
    public var resetAnalyticsData: @Sendable () -> Void

    public init(
        logEvent: @Sendable @escaping (AnalyticsEvent) -> Void,
        setUserProperty: @Sendable @escaping (_ value: String?, _ property: AnalyticsUserProperty) -> Void,
        isCollectionEnabled: @Sendable @escaping () -> Bool,
        setCollectionEnabled: @Sendable @escaping (Bool) -> Void,
        resetAnalyticsData: @Sendable @escaping () -> Void
    ) {
        self.logEvent = logEvent
        self.setUserProperty = setUserProperty
        self.isCollectionEnabled = isCollectionEnabled
        self.setCollectionEnabled = setCollectionEnabled
        self.resetAnalyticsData = resetAnalyticsData
    }
}

extension AnalyticsClient: DependencyKey {
    public static let liveValue: Self = .noop
    public static let testValue: Self = .noop
    public static let previewValue: Self = .noop

    static let noop = Self(
        logEvent: { _ in },
        setUserProperty: { _, _ in },
        isCollectionEnabled: { true },
        setCollectionEnabled: { _ in },
        resetAnalyticsData: {}
    )
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
