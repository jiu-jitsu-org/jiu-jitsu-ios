//
//  BeltPromptClient.swift
//  Presentation
//

import Foundation
import ComposableArchitecture

/// 띠 묻기 시트(#130)의 노출 기록 — 7일 미루기 · 하루 한 번 확인 (기기 저장)
public struct BeltPromptClient: Sendable {
    /// 지금 띠가 있는지 확인해 봐도 되는가
    public var canCheck: @Sendable (Date) -> Bool
    /// 오늘 확인을 마쳤다고 남긴다
    public var markChecked: @Sendable (Date) -> Void
    /// '나중에' — 7일 동안 띄우지 않는다
    public var snooze: @Sendable (Date) -> Void

    public init(
        canCheck: @Sendable @escaping (Date) -> Bool,
        markChecked: @Sendable @escaping (Date) -> Void,
        snooze: @Sendable @escaping (Date) -> Void
    ) {
        self.canCheck = canCheck
        self.markChecked = markChecked
        self.snooze = snooze
    }
}

extension BeltPromptClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    /// 테스트에서는 묻지 않는다 — 시트를 다루는 테스트만 바꿔 끼운다
    public static let testValue = BeltPromptClient(
        canCheck: { _ in false },
        markChecked: { _ in },
        snooze: { _ in }
    )

    /// 프리뷰에서는 늘 묻는다
    public static let previewValue = BeltPromptClient(
        canCheck: { _ in true },
        markChecked: { _ in },
        snooze: { _ in }
    )
}

extension DependencyValues {
    public var beltPromptClient: BeltPromptClient {
        get { self[BeltPromptClient.self] }
        set { self[BeltPromptClient.self] = newValue }
    }
}

extension BeltPromptClient {
    static let unimplemented: Self = Self(
        canCheck: { _ in
            fatalError("BeltPromptClient.canCheck is not implemented")
        },
        markChecked: { _ in
            fatalError("BeltPromptClient.markChecked is not implemented")
        },
        snooze: { _ in
            fatalError("BeltPromptClient.snooze is not implemented")
        }
    )
}
