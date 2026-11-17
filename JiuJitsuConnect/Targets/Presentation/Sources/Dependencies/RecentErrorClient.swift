//
//  RecentErrorClient.swift
//  Presentation
//
//  앱을 켜 둔 동안 마지막으로 사용자에게 보인 오류 코드(#379). 문의 메일 본문에 한 줄로 붙여,
//  가입 전처럼 회원 번호가 없을 때도 서버 기록에서 찾을 수 있게 한다. 기기에 저장하지 않는다.
//

import ComposableArchitecture
import Foundation

/// 사용자에게 보인 오류 코드와 그 시각.
public struct RecentError: Equatable, Sendable {
    public let code: String
    public let occurredAt: Date

    public init(code: String, occurredAt: Date) {
        self.code = code
        self.occurredAt = occurredAt
    }
}

public struct RecentErrorClient: Sendable {
    public var record: @Sendable (RecentError) -> Void
    public var latest: @Sendable () -> RecentError?

    public init(
        record: @Sendable @escaping (RecentError) -> Void,
        latest: @Sendable @escaping () -> RecentError?
    ) {
        self.record = record
        self.latest = latest
    }

    /// 메모리에만 두는 저장소. 앱을 다시 켜면 비워진다.
    static func inMemory() -> Self {
        let storage = LockIsolated<RecentError?>(nil)
        return Self(
            record: { error in storage.setValue(error) },
            latest: { storage.value }
        )
    }
}

extension RecentErrorClient: DependencyKey {
    public static let liveValue: Self = .inMemory()
    public static var testValue: Self { .inMemory() }
    public static let previewValue: Self = Self(record: { _ in }, latest: { nil })
}

public extension DependencyValues {
    var recentErrorClient: RecentErrorClient {
        get { self[RecentErrorClient.self] }
        set { self[RecentErrorClient.self] = newValue }
    }
}
