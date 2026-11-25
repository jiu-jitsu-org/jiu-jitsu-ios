//
//  LegacyHeaderPatternStorage.swift
//  Data
//

import Foundation

/// MY 상단 바탕 무늬를 서버에 저장하기 전(#320) 이 기기에만 남긴 값.
///
/// 이제 무늬는 서버가 기준이라(#337) 처음 한 번 서버로 옮겨 담은 뒤 지운다.
/// 예전 화면이 `@AppStorage`로 무늬 이름(`oss` 등)을 그대로 저장해 같은 키·값을 읽는다.
public final class LegacyHeaderPatternStorage: @unchecked Sendable {
    private static let key = "myHeaderPattern"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 남아 있는 무늬 이름. 고른 적 없거나 이미 옮겨 담았으면 nil.
    public func load() -> String? {
        defaults.string(forKey: Self.key)
    }

    public func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
