//
//  AppVersionClient.swift
//  Presentation
//
//  서버의 최소 · 최신 앱 버전 확인과 업데이트 안내 기록(#326).
//  스플래시에서 받은 값을 앱 전체(앱 복귀 · 설정 > 버전 정보)가 같이 쓰도록 마지막 결과를 기억한다.
//

import ComposableArchitecture
import Domain
import Foundation

public struct AppVersionClient: Sendable {
    /// 지금 설치된 버전 (`CFBundleShortVersionString`)
    public var currentVersion: @Sendable () -> String
    /// 서버에서 새로 받는다. 받은 값은 `lastChecked`로 앱 전체가 같이 본다.
    public var fetchPolicy: @Sendable () async throws -> AppVersionPolicy
    /// 이번 실행에서 마지막으로 받은 값과 받은 때. 아직 못 받았으면 nil.
    public var lastChecked: @Sendable () -> CheckedAppVersionPolicy?
    /// 권장 업데이트 안내에서 '나중에'를 누른 최신 버전. 같은 버전으로는 다시 안내하지 않는다.
    public var dismissedRecommendedVersion: @Sendable () -> String?
    public var setDismissedRecommendedVersion: @Sendable (String) -> Void
    /// 스토어의 앱 페이지. 앱 ID가 정해지기 전에는 nil.
    public var storeURL: @Sendable () -> URL?

    public init(
        currentVersion: @Sendable @escaping () -> String,
        fetchPolicy: @Sendable @escaping () async throws -> AppVersionPolicy,
        lastChecked: @Sendable @escaping () -> CheckedAppVersionPolicy?,
        dismissedRecommendedVersion: @Sendable @escaping () -> String?,
        setDismissedRecommendedVersion: @Sendable @escaping (String) -> Void,
        storeURL: @Sendable @escaping () -> URL?
    ) {
        self.currentVersion = currentVersion
        self.fetchPolicy = fetchPolicy
        self.lastChecked = lastChecked
        self.dismissedRecommendedVersion = dismissedRecommendedVersion
        self.setDismissedRecommendedVersion = setDismissedRecommendedVersion
        self.storeURL = storeURL
    }
}

public struct CheckedAppVersionPolicy: Equatable, Sendable {
    public let policy: AppVersionPolicy
    public let checkedAt: Date

    public init(policy: AppVersionPolicy, checkedAt: Date) {
        self.policy = policy
        self.checkedAt = checkedAt
    }
}

public extension AppVersionClient {
    /// 켜 둔 앱을 다시 열 때 · 설정을 열 때, 마지막 확인 뒤 이만큼 지났으면 다시 확인한다.
    static let recheckInterval: TimeInterval = 6 * 60 * 60

    /// 마지막 확인이 없거나 오래됐는지
    func needsRecheck(now: Date) -> Bool {
        guard let checked = lastChecked() else { return true }
        return now.timeIntervalSince(checked.checkedAt) >= Self.recheckInterval
    }
}

/// 마지막으로 받은 버전 정책. 앱 실행 동안만 기억한다 — 다음 실행은 스플래시가 다시 받는다.
public final class AppVersionPolicyCache: Sendable {
    private let storage = Storage()

    public init() {}

    public func load() -> CheckedAppVersionPolicy? {
        storage.value
    }

    public func store(_ policy: AppVersionPolicy, at date: Date) {
        storage.value = CheckedAppVersionPolicy(policy: policy, checkedAt: date)
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var _value: CheckedAppVersionPolicy?

        var value: CheckedAppVersionPolicy? {
            get { lock.withLock { _value } }
            set { lock.withLock { _value = newValue } }
        }
    }
}

extension AppVersionClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = .unimplemented

    public static let previewValue: Self = Self(
        currentVersion: { "1.0.0" },
        fetchPolicy: { AppVersionPolicy(minimumVersion: "1.0.0", latestVersion: "1.1.0") },
        lastChecked: { CheckedAppVersionPolicy(policy: AppVersionPolicy(minimumVersion: "1.0.0", latestVersion: "1.1.0"), checkedAt: Date()) },
        dismissedRecommendedVersion: { nil },
        setDismissedRecommendedVersion: { _ in },
        storeURL: { nil }
    )
}

public extension DependencyValues {
    var appVersionClient: AppVersionClient {
        get { self[AppVersionClient.self] }
        set { self[AppVersionClient.self] = newValue }
    }
}

extension AppVersionClient {
    static let unimplemented: Self = Self(
        currentVersion: { fatalError("appVersionClient.currentVersion is not implemented") },
        fetchPolicy: { fatalError("appVersionClient.fetchPolicy is not implemented") },
        lastChecked: { fatalError("appVersionClient.lastChecked is not implemented") },
        dismissedRecommendedVersion: { fatalError("appVersionClient.dismissedRecommendedVersion is not implemented") },
        setDismissedRecommendedVersion: { _ in fatalError("appVersionClient.setDismissedRecommendedVersion is not implemented") },
        storeURL: { fatalError("appVersionClient.storeURL is not implemented") }
    )
}
