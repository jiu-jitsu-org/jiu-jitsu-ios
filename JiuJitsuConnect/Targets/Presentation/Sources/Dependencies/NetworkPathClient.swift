//
//  NetworkPathClient.swift
//  Presentation
//
//  기기가 망에 닿아 있는지(#396). 연결 문제로 불러오지 못한 웹 화면이 연결이 돌아오는 때를 알려고 쓴다.
//

import ComposableArchitecture
import Foundation
import Network

public struct NetworkPathClient: Sendable {
    /// 구독할 때마다 감시를 새로 시작하고, 구독을 끊으면 멈춘다. 처음엔 지금 상태, 그 뒤로는 바뀔 때마다 온다.
    /// true면 망에 닿아 있음(`NWPath.Status.satisfied`).
    public var isConnectedUpdates: @Sendable () -> AsyncStream<Bool>

    public init(isConnectedUpdates: @Sendable @escaping () -> AsyncStream<Bool>) {
        self.isConnectedUpdates = isConnectedUpdates
    }
}

extension NetworkPathClient: DependencyKey {
    public static let liveValue = NetworkPathClient(
        isConnectedUpdates: {
            AsyncStream { continuation in
                let monitor = NWPathMonitor()
                monitor.pathUpdateHandler = { path in
                    continuation.yield(path.status == .satisfied)
                }
                continuation.onTermination = { _ in monitor.cancel() }
                monitor.start(queue: DispatchQueue(label: "NetworkPathClient"))
            }
        }
    )

    public static let testValue = NetworkPathClient(
        isConnectedUpdates: unimplemented(
            "NetworkPathClient.isConnectedUpdates",
            placeholder: AsyncStream { $0.finish() }
        )
    )

    public static let previewValue = NetworkPathClient(
        isConnectedUpdates: {
            AsyncStream {
                $0.yield(true)
                $0.finish()
            }
        }
    )
}

extension DependencyValues {
    public var networkPathClient: NetworkPathClient {
        get { self[NetworkPathClient.self] }
        set { self[NetworkPathClient.self] = newValue }
    }
}
