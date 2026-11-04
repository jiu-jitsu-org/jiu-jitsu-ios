//
//  GreetingStorage.swift
//  Data
//

import Foundation

/// 재방문 인사 장면을 오늘 틀어도 되는지 정하는 노출 기록(#223).
/// "하루"는 기기 현지 날짜로 센다.
public final class GreetingStorage: @unchecked Sendable {
    private static let key = "greeting-last-played-day"

    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
    }

    /// 오늘 아직 인사 장면을 틀지 않았는가
    public func shouldPlay(now: Date) -> Bool {
        defaults.string(forKey: Self.key) != day(of: now)
    }

    /// 오늘 인사 장면을 틀었다고 남긴다
    public func markPlayed(now: Date) {
        defaults.set(day(of: now), forKey: Self.key)
    }

    private func day(of date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
