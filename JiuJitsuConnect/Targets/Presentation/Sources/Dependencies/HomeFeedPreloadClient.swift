//
//  HomeFeedPreloadClient.swift
//  Presentation
//
//  스플래시가 홈 피드 웹을 미리 불러 두거나(#270), 미리 불러 둘 수 없으면 웹킷만 데워 둔다(#207).
//  실제 웹뷰를 다루는 일은 HomeFeedPreloader가 하고, 스플래시 Reducer는 이 클라이언트로 언제 할지만 정한다.
//

import ComposableArchitecture
import Foundation

public struct HomeFeedPreloadClient: Sendable {
    /// 빈 웹뷰를 하나 만들어 웹킷을 데워 둔다.
    public var prewarm: @Sendable () async -> Void
    /// 홈 피드를 이 토큰의 세션으로 미리 불러 둔다. 홈 웹뷰가 생기면 이어받는다.
    public var preload: @Sendable (_ url: URL, _ accessToken: String) async -> Void
    /// 홈이 생기지 않을 때(로그인 화면으로 감) 미리 불러 둔 화면을 버린다.
    public var discard: @Sendable () async -> Void

    public init(
        prewarm: @Sendable @escaping () async -> Void,
        preload: @Sendable @escaping (_ url: URL, _ accessToken: String) async -> Void,
        discard: @Sendable @escaping () async -> Void
    ) {
        self.prewarm = prewarm
        self.preload = preload
        self.discard = discard
    }
}

extension HomeFeedPreloadClient: DependencyKey {
    public static let liveValue = HomeFeedPreloadClient(
        prewarm: { await HomeFeedPreloader.prewarm() },
        preload: { url, accessToken in await HomeFeedPreloader.preload(url: url, accessToken: accessToken) },
        discard: { await HomeFeedPreloader.discard() }
    )

    /// 테스트에서는 웹뷰를 만들지 않는다
    public static let testValue = HomeFeedPreloadClient(
        prewarm: {},
        preload: { _, _ in },
        discard: {}
    )

    public static let previewValue = testValue
}

public extension DependencyValues {
    var homeFeedPreloadClient: HomeFeedPreloadClient {
        get { self[HomeFeedPreloadClient.self] }
        set { self[HomeFeedPreloadClient.self] = newValue }
    }
}
