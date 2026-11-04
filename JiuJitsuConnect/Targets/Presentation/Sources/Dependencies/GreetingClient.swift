//
//  GreetingClient.swift
//  Presentation
//

import Foundation
import ComposableArchitecture

/// 재방문 인사 장면의 노출 기록 — 전체 장면은 하루 첫 실행에만 보여 준다(#223, 기기 저장)
public struct GreetingClient: Sendable {
    /// 오늘 아직 인사 장면을 틀지 않았는가
    public var shouldPlay: @Sendable (Date) -> Bool
    /// 오늘 인사 장면을 틀었다고 남긴다
    public var markPlayed: @Sendable (Date) -> Void

    public init(
        shouldPlay: @Sendable @escaping (Date) -> Bool,
        markPlayed: @Sendable @escaping (Date) -> Void
    ) {
        self.shouldPlay = shouldPlay
        self.markPlayed = markPlayed
    }
}

extension GreetingClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    /// 테스트에서는 틀지 않는다 — 인사를 다루는 테스트만 바꿔 끼운다
    public static let testValue = GreetingClient(
        shouldPlay: { _ in false },
        markPlayed: { _ in }
    )

    /// 프리뷰에서는 늘 튼다
    public static let previewValue = GreetingClient(
        shouldPlay: { _ in true },
        markPlayed: { _ in }
    )
}

extension DependencyValues {
    public var greetingClient: GreetingClient {
        get { self[GreetingClient.self] }
        set { self[GreetingClient.self] = newValue }
    }
}

extension GreetingClient {
    static let unimplemented: Self = Self(
        shouldPlay: { _ in
            fatalError("GreetingClient.shouldPlay is not implemented")
        },
        markPlayed: { _ in
            fatalError("GreetingClient.markPlayed is not implemented")
        }
    )
}
