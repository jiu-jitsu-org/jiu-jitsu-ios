//
//  AuthSessionEventClient.swift
//  Presentation
//
//  네트워크 레이어(401 인터셉터)가 방송하는 세션 이벤트를 TCA에서 구독하기 위한 의존성.
//  네이티브가 토큰을 자동 갱신하면 웹뷰에 새 토큰을 주입하고, refresh까지 실패해 세션이 만료되면
//  게스트로 전환하기 위해 AppTabFeature가 이 스트림을 구독한다.
//

import ComposableArchitecture
import Domain

public struct AuthSessionEventClient {
    /// 구독 스트림을 발급한다. 구독자별로 독립 스트림이 생성된다.
    public var events: @Sendable () -> AsyncStream<AuthSessionEvent>

    public init(events: @Sendable @escaping () -> AsyncStream<AuthSessionEvent>) {
        self.events = events
    }
}

extension AuthSessionEventClient: DependencyKey {
    // 실제 브로드캐스터는 App Composition Root에서 주입한다. 기본값은 즉시 종료되는 빈 스트림.
    public static let liveValue: Self = Self(events: { AsyncStream { $0.finish() } })
    public static let testValue: Self = Self(events: { AsyncStream { $0.finish() } })
}

public extension DependencyValues {
    var authSessionEventClient: AuthSessionEventClient {
        get { self[AuthSessionEventClient.self] }
        set { self[AuthSessionEventClient.self] = newValue }
    }
}
