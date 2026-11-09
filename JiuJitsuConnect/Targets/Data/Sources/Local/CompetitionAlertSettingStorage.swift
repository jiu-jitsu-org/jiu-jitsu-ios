//
//  CompetitionAlertSettingStorage.swift
//  Data
//

import Foundation

/// 설정 › 알림의 '관심 대회 알림' 켬/끔(#255). 기본은 꺼짐이다.
/// 알림 설정 API(`/api/notice/setting`)에 아직 이 항목이 없어 기기에 둔다 —
/// 백엔드가 필드를 더하면 NoticeSetting으로 옮기고 이 저장소는 지운다.
public final class CompetitionAlertSettingStorage: @unchecked Sendable {
    private static let key = "competition-alert-enabled"

    private let defaults: UserDefaults
    // 값 변경 구독자. 탭이 살아 있어 다른 탭에서 바꾼 값을 열린 설정 화면이 받아야 한다.
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isEnabled() -> Bool {
        defaults.bool(forKey: Self.key)
    }

    public func setEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Self.key)
        lock.lock()
        let snapshot = Array(continuations.values)
        lock.unlock()
        snapshot.forEach { $0.yield(isEnabled) }
    }

    /// 새 구독 스트림을 발급한다. 구독이 끝나면 내부 continuation은 자동으로 지운다.
    public func changes() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.continuations[id] = nil
                self.lock.unlock()
            }
        }
    }
}
