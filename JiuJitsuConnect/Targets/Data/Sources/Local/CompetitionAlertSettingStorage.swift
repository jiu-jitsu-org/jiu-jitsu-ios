//
//  CompetitionAlertSettingStorage.swift
//  Data
//

import Foundation

/// 설정 › 알림의 '관심 대회 알림' 켬/끔(#255). 기본은 꺼짐이다.
/// 알림 설정 API(`/api/notice/setting`)에 아직 이 항목이 없어 기기에 둔다 —
/// 백엔드가 필드를 더하면 NoticeSetting으로 옮기고 이 저장소는 지운다.
/// 사람마다의 설정이라 회원 id별로 따로 둔다 — 로그아웃·세션 만료 뒤 같은 사람이 다시 로그인하면 값이 그대로다.
public final class CompetitionAlertSettingStorage: @unchecked Sendable {
    private static let keyPrefix = "competition-alert-enabled"

    private let defaults: UserDefaults
    // 값 변경 구독자(회원 id별). 탭이 살아 있어 다른 탭에서 바꾼 값을 열린 설정 화면이 받아야 한다.
    private let lock = NSLock()
    private var subscribers: [UUID: (userId: Int, continuation: AsyncStream<Bool>.Continuation)] = [:]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isEnabled(userId: Int) -> Bool {
        defaults.bool(forKey: Self.key(userId: userId))
    }

    public func setEnabled(_ isEnabled: Bool, userId: Int) {
        defaults.set(isEnabled, forKey: Self.key(userId: userId))
        lock.lock()
        let targets = subscribers.values.filter { $0.userId == userId }.map(\.continuation)
        lock.unlock()
        targets.forEach { $0.yield(isEnabled) }
    }

    /// 이 회원의 값이 바뀔 때마다 새 값을 흘리는 스트림. 구독이 끝나면 자동으로 지운다.
    public func changes(userId: Int) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            subscribers[id] = (userId, continuation)
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.subscribers[id] = nil
                self.lock.unlock()
            }
        }
    }

    private static func key(userId: Int) -> String {
        "\(keyPrefix).\(userId)"
    }
}
