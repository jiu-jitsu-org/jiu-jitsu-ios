//
//  AuthSessionEvent.swift
//  Domain
//
//  네트워크 레이어(401 인터셉터)에서 발생한 세션 변화를 Presentation(TCA)으로 전달하는 채널.
//  - 네이티브 API가 토큰을 자동 갱신하면 웹뷰의 인메모리 토큰도 동기화해야 하므로 `.tokenRefreshed`를,
//  - refresh 토큰까지 만료돼 갱신이 불가능하면 `.sessionExpired`를 방송한다.
//
//  Data·Presentation 양쪽이 공유하는 계약이라 의존성이 없는 Domain에 둔다.
//  (NotificationCenter 신규 사용 금지 정책에 따라 AsyncStream 기반 브로드캐스터로 구현한다.)
//

import Foundation

public enum AuthSessionEvent: Sendable, Equatable {
    /// 토큰 자동 갱신 성공 — 웹뷰에 새 accessToken을 주입해야 한다.
    case tokenRefreshed(accessToken: String, expiresAt: Int?)
    /// refresh 토큰까지 만료 — 세션을 정리하고 게스트로 전환해야 한다.
    case sessionExpired
}

/// 여러 구독자(재구독 포함)에게 세션 이벤트를 방송한다. App Composition Root에서 단일 인스턴스로
/// 생성해 NetworkService(발신)와 TCA 의존성(수신) 양쪽에 주입한다.
public final class AuthSessionEventBroadcaster: Sendable {
    private let storage = Storage()

    public init() {}

    /// 새 구독 스트림을 발급한다. 구독 종료 시 내부 continuation은 자동 제거된다.
    public func events() -> AsyncStream<AuthSessionEvent> {
        AsyncStream { continuation in
            let id = storage.add(continuation)
            continuation.onTermination = { [storage] _ in
                storage.remove(id)
            }
        }
    }

    /// 모든 활성 구독자에게 이벤트를 전달한다.
    public func send(_ event: AuthSessionEvent) {
        storage.broadcast(event)
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [UUID: AsyncStream<AuthSessionEvent>.Continuation] = [:]

        func add(_ continuation: AsyncStream<AuthSessionEvent>.Continuation) -> UUID {
            let id = UUID()
            lock.lock(); defer { lock.unlock() }
            continuations[id] = continuation
            return id
        }

        func remove(_ id: UUID) {
            lock.lock(); defer { lock.unlock() }
            continuations[id] = nil
        }

        func broadcast(_ event: AuthSessionEvent) {
            lock.lock()
            let snapshot = Array(continuations.values)
            lock.unlock()
            snapshot.forEach { $0.yield(event) }
        }
    }
}
