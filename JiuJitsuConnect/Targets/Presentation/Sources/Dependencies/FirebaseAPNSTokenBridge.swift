//
//  FirebaseAPNSTokenBridge.swift
//  Presentation
//

import Foundation

public enum FirebaseAPNSTokenBridgeError: Error, Sendable {
    case registrationTimedOut
}

/// `AppDelegate`에서 APNs 등록 결과를 전달하고, FCM 토큰 발급 전에 동기화합니다.
/// 동시에 여러 `waitForDeviceToken` 호출이 있어도 **한 번의 APNs 결과를 모두에게** 전달합니다.
public enum FirebaseAPNSTokenBridge: Sendable {
    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var waiters: [(id: UUID, continuation: CheckedContinuation<Data, Error>)] = []
        private var pendingToken: Data?

        func takePendingTokenIfAny() -> Data? {
            lock.lock()
            defer { lock.unlock() }
            guard let t = pendingToken else { return nil }
            pendingToken = nil
            return t
        }

        /// 대기열에 등록합니다. 이미 `pendingToken`이 있으면 즉시 resume하고 `nil`을 반환합니다(등록 취소 불필요).
        @discardableResult
        func registerWaiter(_ cont: CheckedContinuation<Data, Error>) -> UUID? {
            let id = UUID()
            lock.lock()
            defer { lock.unlock() }
            if let t = pendingToken {
                pendingToken = nil
                cont.resume(returning: t)
                return nil
            }
            waiters.append((id, cont))
            return id
        }

        func unregisterWaiter(id: UUID) {
            lock.lock()
            defer { lock.unlock() }
            guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
            let (_, cont) = waiters.remove(at: index)
            cont.resume(throwing: CancellationError())
        }

        func deliver(_ token: Data) {
            lock.lock()
            let batch = waiters
            waiters.removeAll()
            lock.unlock()
            if batch.isEmpty {
                lock.lock()
                pendingToken = token
                lock.unlock()
            } else {
                for (_, cont) in batch {
                    cont.resume(returning: token)
                }
            }
        }

        func deliverFailure(_ error: Error) {
            lock.lock()
            let batch = waiters
            waiters.removeAll()
            pendingToken = nil
            lock.unlock()
            for (_, cont) in batch {
                cont.resume(throwing: error)
            }
        }
    }

    private static let storage = Storage()

    public static func waitForDeviceToken(timeoutSeconds: UInt64 = 25) async throws -> Data {
        if let token = storage.takePendingTokenIfAny() {
            return token
        }

        final class WaiterHandle: @unchecked Sendable {
            var waiterId: UUID?
        }
        let handle = WaiterHandle()

        return try await withTaskCancellationHandler {
            let timeoutNanoseconds = timeoutSeconds * 1_000_000_000
            let timeoutTask = Task {
                do {
                    try await Task.sleep(nanoseconds: timeoutNanoseconds)
                    storage.deliverFailure(FirebaseAPNSTokenBridgeError.registrationTimedOut)
                } catch {
                    // sleep 취소
                }
            }
            defer { timeoutTask.cancel() }

            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
                handle.waiterId = storage.registerWaiter(cont)
            }
        } onCancel: {
            if let id = handle.waiterId {
                storage.unregisterWaiter(id: id)
            }
        }
    }

    public static func deliverDeviceToken(_ token: Data) {
        storage.deliver(token)
    }

    public static func deliverRegistrationFailure(_ error: Error) {
        storage.deliverFailure(error)
    }
}
