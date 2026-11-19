//
//  PushNotificationClient.swift
//  Presentation
//
//  AppDelegate(UNUserNotificationCenterDelegate)가 받은 푸시 탭을 TCA(AppFeature)로 전달하는 의존성.
//  스토어는 SwiftUI App이 만들고 AppDelegate는 그보다 먼저 살아 있어 직접 참조할 수 없으므로,
//  AuthSessionEvent처럼 AsyncStream 릴레이를 App Composition Root에서 양쪽에 주입한다.
//

import ComposableArchitecture
import Foundation

public struct PushNotificationClient: Sendable {
    /// 사용자가 탭한 푸시의 payload 스트림. 구독자별로 독립 스트림이 생성된다.
    public var taps: @Sendable () -> AsyncStream<PushActionPayload>
    /// 앱을 쓰는 중에 알림이 도착함(#394). 배너만 뜨고 앱 안 새 알림 점은 그대로라, 받는 쪽이 다시 조회한다.
    public var arrivals: @Sendable () -> AsyncStream<Void>

    public init(
        taps: @Sendable @escaping () -> AsyncStream<PushActionPayload>,
        arrivals: @Sendable @escaping () -> AsyncStream<Void>
    ) {
        self.taps = taps
        self.arrivals = arrivals
    }
}

extension PushNotificationClient: DependencyKey {
    // 실제 릴레이는 App Composition Root에서 주입한다. 기본값은 즉시 종료되는 빈 스트림.
    public static let liveValue: Self = Self(taps: { AsyncStream { $0.finish() } }, arrivals: { AsyncStream { $0.finish() } })
    public static let testValue: Self = Self(taps: { AsyncStream { $0.finish() } }, arrivals: { AsyncStream { $0.finish() } })
    public static let previewValue: Self = Self(taps: { AsyncStream { $0.finish() } }, arrivals: { AsyncStream { $0.finish() } })
}

public extension DependencyValues {
    var pushNotificationClient: PushNotificationClient {
        get { self[PushNotificationClient.self] }
        set { self[PushNotificationClient.self] = newValue }
    }
}

/// 푸시 탭 payload를 구독자에게 방송한다. App Composition Root에서 단일 인스턴스로 생성해
/// AppDelegate(발신)와 `PushNotificationClient`(수신) 양쪽에 주입한다.
///
/// 콜드 스타트에서는 `didReceive` 콜백이 AppFeature의 구독보다 먼저 올 수 있다. 그때의 탭을
/// 잃지 않도록 구독자가 없으면 마지막 payload를 보관했다가 첫 구독자에게 넘긴다.
/// 보관한 탭은 콜드 스타트로 표시한다 — 분석이 앱을 켠 탭인지 가린다(#427).
/// (탭은 사용자 의도 하나이므로 여러 개가 쌓여도 마지막 것만 유효하다.)
public final class PushNotificationTapRelay: Sendable {
    private let storage = Storage()

    public init() {}

    /// 새 구독 스트림을 발급한다. 보관 중인 payload가 있으면 즉시 흘려보낸다.
    public func taps() -> AsyncStream<PushActionPayload> {
        AsyncStream { continuation in
            let id = storage.add(continuation)
            continuation.onTermination = { [storage] _ in
                storage.remove(id)
            }
        }
    }

    /// 모든 활성 구독자에게 전달한다. 구독자가 없으면 보관한다.
    public func send(_ payload: PushActionPayload) {
        storage.broadcast(payload)
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [UUID: AsyncStream<PushActionPayload>.Continuation] = [:]
        private var pending: PushActionPayload?

        func add(_ continuation: AsyncStream<PushActionPayload>.Continuation) -> UUID {
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            let pending = self.pending
            self.pending = nil
            lock.unlock()
            if let pending {
                continuation.yield(pending)
            }
            return id
        }

        func remove(_ id: UUID) {
            lock.lock(); defer { lock.unlock() }
            continuations[id] = nil
        }

        func broadcast(_ payload: PushActionPayload) {
            lock.lock()
            let snapshot = Array(continuations.values)
            if snapshot.isEmpty {
                var held = payload
                held.isColdStart = true
                pending = held
            }
            lock.unlock()
            snapshot.forEach { $0.yield(payload) }
        }
    }
}

/// 앱을 쓰는 중 도착한 알림을 구독자에게 알린다(#394).
///
/// 푸시 탭 릴레이와 달리 구독자가 없을 때 온 알림은 보관하지 않는다. 그때는 아직 탭 화면이 없어,
/// 홈에 들어가며 새 알림 점을 처음 조회할 때 반영된다.
public final class PushNotificationArrivalRelay: Sendable {
    private let storage = Storage()

    public init() {}

    public func arrivals() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let id = storage.add(continuation)
            continuation.onTermination = { [storage] _ in
                storage.remove(id)
            }
        }
    }

    public func send() {
        storage.broadcast()
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

        func add(_ continuation: AsyncStream<Void>.Continuation) -> UUID {
            let id = UUID()
            lock.lock(); defer { lock.unlock() }
            continuations[id] = continuation
            return id
        }

        func remove(_ id: UUID) {
            lock.lock(); defer { lock.unlock() }
            continuations[id] = nil
        }

        func broadcast() {
            lock.lock()
            let snapshot = Array(continuations.values)
            lock.unlock()
            snapshot.forEach { $0.yield() }
        }
    }
}
