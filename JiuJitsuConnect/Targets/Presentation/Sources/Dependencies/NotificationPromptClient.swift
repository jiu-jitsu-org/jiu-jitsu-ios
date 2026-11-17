//
//  NotificationPromptClient.swift
//  Presentation
//

import Foundation
import ComposableArchitecture

/// 알림 권한 안내 시트(#333)의 노출 기록 — 7일 미루기 · 3번이면 그만 (기기 저장)
public struct NotificationPromptClient: Sendable {
    /// 지금 안내를 띄워도 되는가
    public var canPrompt: @Sendable (Date) -> Bool
    /// '나중에' — 7일 동안 띄우지 않고 횟수를 센다
    public var snooze: @Sendable (Date) -> Void

    public init(
        canPrompt: @Sendable @escaping (Date) -> Bool,
        snooze: @Sendable @escaping (Date) -> Void
    ) {
        self.canPrompt = canPrompt
        self.snooze = snooze
    }
}

extension NotificationPromptClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    /// 테스트에서는 묻지 않는다 — 시트를 다루는 테스트만 바꿔 끼운다
    public static let testValue = NotificationPromptClient(
        canPrompt: { _ in false },
        snooze: { _ in }
    )

    /// 프리뷰에서는 늘 묻는다
    public static let previewValue = NotificationPromptClient(
        canPrompt: { _ in true },
        snooze: { _ in }
    )
}

extension DependencyValues {
    public var notificationPromptClient: NotificationPromptClient {
        get { self[NotificationPromptClient.self] }
        set { self[NotificationPromptClient.self] = newValue }
    }
}

extension NotificationPromptClient {
    static let unimplemented: Self = Self(
        canPrompt: { _ in
            fatalError("NotificationPromptClient.canPrompt is not implemented")
        },
        snooze: { _ in
            fatalError("NotificationPromptClient.snooze is not implemented")
        }
    )
}
