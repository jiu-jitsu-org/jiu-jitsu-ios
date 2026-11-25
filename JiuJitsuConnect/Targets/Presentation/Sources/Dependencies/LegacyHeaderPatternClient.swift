//
//  LegacyHeaderPatternClient.swift
//  Presentation
//

import Foundation
import ComposableArchitecture

/// 서버에 저장하기 전 이 기기에만 남긴 MY 상단 무늬(#320) — 서버로 한 번 옮겨 담는 데 쓴다(#337).
public struct LegacyHeaderPatternClient: Sendable {
    /// 기기에 남은 무늬. 없거나 이 앱이 모르는 이름(없어진 무늬)이면 nil.
    public var load: @Sendable () -> MyHeaderPattern?
    /// 옮겨 담았거나 서버에 이미 무늬가 있어 기기 값을 지운다.
    public var clear: @Sendable () -> Void

    public init(
        load: @Sendable @escaping () -> MyHeaderPattern?,
        clear: @Sendable @escaping () -> Void
    ) {
        self.load = load
        self.clear = clear
    }
}

extension LegacyHeaderPatternClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    /// 테스트에서는 기기 값이 없다 — 옮겨 담기를 다루는 테스트만 바꿔 끼운다
    public static let testValue = LegacyHeaderPatternClient(
        load: { nil },
        clear: { }
    )

    /// 프리뷰에서도 기기 값이 없다 — 서버 값(또는 기본 무늬)으로 그린다
    public static let previewValue = LegacyHeaderPatternClient(
        load: { nil },
        clear: { }
    )
}

extension DependencyValues {
    public var legacyHeaderPatternClient: LegacyHeaderPatternClient {
        get { self[LegacyHeaderPatternClient.self] }
        set { self[LegacyHeaderPatternClient.self] = newValue }
    }
}

extension LegacyHeaderPatternClient {
    static let unimplemented: Self = Self(
        load: {
            fatalError("LegacyHeaderPatternClient.load is not implemented")
        },
        clear: {
            fatalError("LegacyHeaderPatternClient.clear is not implemented")
        }
    )
}
