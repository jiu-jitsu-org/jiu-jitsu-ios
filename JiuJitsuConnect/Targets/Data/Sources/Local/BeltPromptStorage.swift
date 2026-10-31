//
//  BeltPromptStorage.swift
//  Data
//

import Foundation

/// 띠 묻기 시트(#130)를 띄워도 되는지 정하는 노출 기록 — 웹 `belt-prompt-policy.ts`와 같은 규칙.
///
/// - '나중에'(또는 바깥으로 닫기)를 누르면 7일 동안 띄우지 않는다.
/// - 하루에 한 번까지만 확인한다 — 띠가 있는지 서버에 묻는 것도 그날의 한 번으로 친다.
///
/// 서버에 두지 않고 기기에 둔다(jiu-jitsu-backend#172 합의). 웹이 브릿지로 같은 기록을 읽고 쓸 수 있게
/// 웹 localStorage `belt-prompt`와 같은 모양(`snoozedUntil` ms, `checkedDay` "YYYY-M-D")으로 저장한다.
public final class BeltPromptStorage: @unchecked Sendable {
    private struct Record: Codable {
        var snoozedUntil: Double?
        var checkedDay: String?
    }

    private static let key = "belt-prompt"
    private static let snoozeInterval: TimeInterval = 7 * 24 * 60 * 60

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 지금 띠가 있는지 확인해 봐도 되는가
    public func canCheck(now: Date) -> Bool {
        let record = read()
        if let snoozedUntil = record.snoozedUntil, now.timeIntervalSince1970 * 1000 < snoozedUntil {
            return false
        }
        return record.checkedDay != Self.day(of: now)
    }

    /// 오늘 확인을 마쳤다고 남긴다(띠가 있든 없든, 시트를 띄웠든 아니든)
    public func markChecked(now: Date) {
        var record = read()
        record.checkedDay = Self.day(of: now)
        write(record)
    }

    /// '나중에' — 7일 동안 띄우지 않는다
    public func snooze(now: Date) {
        var record = read()
        record.snoozedUntil = (now.timeIntervalSince1970 + Self.snoozeInterval) * 1000
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

    /// "하루"는 기기 시간의 날짜로 센다 — 웹과 같은 "2026-10-31" 꼴(앞자리 0 없음)
    private static func day(of date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
