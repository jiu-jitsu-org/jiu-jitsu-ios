//
//  NoticeClient.swift
//  Presentation
//
//  알림 목록(새 알림 여부)·수신 설정 조회·변경 TCA Dependency.
//

import ComposableArchitecture
import Domain

public struct NoticeClient: Sendable {
    /// 안 읽은 알림 존재 여부 (GET `/api/notice`의 `isRead == false` 유무)
    public var hasUnread: @Sendable () async throws -> Bool
    /// 알림 수신 설정 조회 (GET `/api/notice/setting`)
    public var fetchSetting: @Sendable () async throws -> NoticeSetting
    /// 알림 수신 설정 변경 (POST `/api/notice/setting`)
    public var updateSetting: @Sendable (NoticeSetting) async throws -> NoticeSetting

    public init(
        hasUnread: @Sendable @escaping () async throws -> Bool,
        fetchSetting: @Sendable @escaping () async throws -> NoticeSetting,
        updateSetting: @Sendable @escaping (NoticeSetting) async throws -> NoticeSetting
    ) {
        self.hasUnread = hasUnread
        self.fetchSetting = fetchSetting
        self.updateSetting = updateSetting
    }
}

extension NoticeClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = .unimplemented

    public static let previewValue: Self = Self(
        hasUnread: { true },
        fetchSetting: {
            NoticeSetting(
                securityEnabled: true,
                serviceEnabled: true,
                communityEnabled: true,
                marketingEnabled: false
            )
        },
        updateSetting: { setting in setting }
    )
}

public extension DependencyValues {
    var noticeClient: NoticeClient {
        get { self[NoticeClient.self] }
        set { self[NoticeClient.self] = newValue }
    }
}

extension NoticeClient {
    static let unimplemented: Self = Self(
        hasUnread: { fatalError("noticeClient.hasUnread is not implemented") },
        fetchSetting: { fatalError("noticeClient.fetchSetting is not implemented") },
        updateSetting: { _ in fatalError("noticeClient.updateSetting is not implemented") }
    )
}
