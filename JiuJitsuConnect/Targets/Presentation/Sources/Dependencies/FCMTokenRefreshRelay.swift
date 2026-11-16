//
//  FCMTokenRefreshRelay.swift
//  Presentation
//
//  AppDelegate(MessagingDelegate)가 받은 FCM 토큰 교체를 TCA(AppTabFeature)로 전달한다(#332).
//  로그인 여부를 아는 Reducer가 서버 등록을 정하도록, 푸시 탭 릴레이처럼 App Composition Root에서 양쪽에 주입한다.
//

import Foundation

/// 바뀐 FCM 토큰을 구독자에게 방송한다.
///
/// 푸시 탭 릴레이와 달리 구독자가 없을 때 온 토큰은 보관하지 않는다. 그때는 아직 탭 화면이 없는
/// 콜드 스타트·로그인 전이라, 앱 진입·로그인 FCM sync가 새 토큰을 발급받아 등록한다.
public final class FCMTokenRefreshRelay: Sendable {
    private let storage = Storage()

    public init() {}

    public func tokens() -> AsyncStream<String> {
        AsyncStream { continuation in
            let id = storage.add(continuation)
            continuation.onTermination = { [storage] _ in
                storage.remove(id)
            }
        }
    }

    public func send(_ token: String) {
        storage.broadcast(token)
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [UUID: AsyncStream<String>.Continuation] = [:]

        func add(_ continuation: AsyncStream<String>.Continuation) -> UUID {
            let id = UUID()
            lock.lock(); defer { lock.unlock() }
            continuations[id] = continuation
            return id
        }

        func remove(_ id: UUID) {
            lock.lock(); defer { lock.unlock() }
            continuations[id] = nil
        }

        func broadcast(_ token: String) {
            lock.lock()
            let snapshot = Array(continuations.values)
            lock.unlock()
            snapshot.forEach { $0.yield(token) }
        }
    }
}
