//
//  NotificationPromptStorage.swift
//  Data
//

import Foundation

/// 알림 권한 안내 시트(#333)를 띄워도 되는지 정하는 기록 (기기 저장).
///
/// - '나중에'(또는 내려 닫기)를 누르면 7일 동안 띄우지 않는다.
/// - '나중에'를 3번 누르면 더 띄우지 않는다. 설정 › 알림에서는 언제든 켤 수 있다.
public final class NotificationPromptStorage: @unchecked Sendable {
    private struct Record: Codable {
        var snoozedUntil: Date?
        var laterCount = 0
    }

    private static let key = "notification-prompt"
    private static let snoozeInterval: TimeInterval = 7 * 24 * 60 * 60
    private static let maxLaterCount = 3

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 지금 안내를 띄워도 되는가
    public func canPrompt(now: Date) -> Bool {
        let record = read()
        guard record.laterCount < Self.maxLaterCount else { return false }
        if let snoozedUntil = record.snoozedUntil, now < snoozedUntil { return false }
        return true
    }

    /// '나중에' — 7일 동안 띄우지 않고 횟수를 센다
    public func snooze(now: Date) {
        var record = read()
        record.laterCount += 1
        record.snoozedUntil = now.addingTimeInterval(Self.snoozeInterval)
        write(record)
    }

    private func read() -> Record {
        guard let data = defaults.data(forKey: Self.key),
              let record = try? JSONDecoder().decode(Record.self, from: data) else { return Record() }
        return record
    }

    private func write(_ record: Record) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
