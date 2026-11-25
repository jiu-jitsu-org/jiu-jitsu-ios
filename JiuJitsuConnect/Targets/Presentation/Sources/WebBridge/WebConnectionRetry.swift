//
//  WebConnectionRetry.swift
//  Presentation
//
//  연결 문제로 불러오지 못한 웹 화면(홈 피드 · 대회 목록 · 쌓인 웹)을 연결이 돌아오면 한 번 저절로 다시 불러온다(#396).
//  지하철처럼 망이 자주 끊기는 곳에서 서버 고장으로 알고 앱을 끄거나 재시도를 연타하지 않게,
//  덮개는 '연결이 불안정해요'로 알리고 연결이 돌아오면 사용자가 누르기 전에 다시 불러온다.
//

import ComposableArchitecture
import SwiftUI

/// 웹 화면 하나의 '연결이 돌아오면 다시 불러오기' 상태.
/// 화면이 보이고, 연결 문제로 실패해 있고, 아직 저절로 다시 불러오지 않았을 때만 연결을 지켜본다.
struct WebConnectionRetry: Equatable, Sendable {
    /// 마지막 로드가 연결 문제로 실패함. 덮개 문구를 가른다.
    private(set) var isConnectionFailure = false
    private var isScreenVisible = false
    /// 이번 실패에서 이미 한 번 저절로 다시 불러옴. 또 실패하면 재시도는 사용자에게 맡긴다 — 망이 오락가락할 때 계속 다시 불러오지 않게.
    private var didAutoReload = false

    var isWatchingConnection: Bool {
        isConnectionFailure && isScreenVisible && !didAutoReload
    }

    mutating func screenVisibilityChanged(_ isVisible: Bool) {
        isScreenVisible = isVisible
    }

    mutating func loadStarted() {
        isConnectionFailure = false
    }

    mutating func loadFailed(_ failure: WebLoadFailure) {
        isConnectionFailure = failure.isConnectionProblem
    }

    mutating func loadSucceeded() {
        isConnectionFailure = false
        didAutoReload = false
    }

    /// 사용자가 다시 불러옴(재시도 · 주소 바꿈 등). 다음 연결 실패도 한 번 저절로 다시 불러올 수 있다.
    mutating func reset() {
        isConnectionFailure = false
        didAutoReload = false
    }

    mutating func autoReloaded() {
        isConnectionFailure = false
        didAutoReload = true
    }

    /// 오류 덮개 문구. 연결 문제면 다시 불러온다는 말은 적지 않는다(웹 jiu-jitsu-frontend#543과 같은 문구).
    var errorTitle: String {
        isConnectionFailure ? "연결이 불안정해요" : "잠시 문제가 생겼어요"
    }

    /// 연결이 돌아온 뒤 다시 불러오기까지 기다리는 시간. 망이 막 붙은 직전엔 주소 찾기 · 경로가 아직 안 잡혀
    /// 한 번뿐인 저절로 다시 불러오기가 또 실패하기 쉽다.
    private static let settleDelay: Duration = .seconds(1)

    /// 지켜볼 때가 되면 연결을 지켜보다 닿으면 `restored`를 보낸다. 지켜볼 때가 아니면 지켜보기를 멈춘다.
    static func watchEffect<Action: Sendable>(
        isWatching: Bool,
        id: some Hashable & Sendable,
        networkPathClient: NetworkPathClient,
        clock: any Clock<Duration>,
        restored: Action
    ) -> Effect<Action> {
        guard isWatching else { return .cancel(id: id) }
        return .run { send in
            // 처음 값이 이미 연결됨이어도 다시 불러온다 — 다른 탭에 있는 동안 연결이 돌아왔을 수 있다.
            for await isConnected in networkPathClient.isConnectedUpdates() where isConnected {
                try await clock.sleep(for: settleDelay)
                await send(restored)
                return
            }
        }
        .cancellable(id: id, cancelInFlight: true)
    }
}

// MARK: - 화면이 보이는지

extension EnvironmentValues {
    /// 이 화면이 든 탭이 지금 고른 탭인지. 탭은 뷰를 유지한 채 투명도로만 가려 onDisappear가 오지 않아 AppTabView가 넣는다.
    @Entry var isTabSelected: Bool = true
}

extension View {
    /// 화면이 사용자에게 보이는지 알린다 — 화면에 올라와 있고(위에 쌓인 화면이 없음), 고른 탭이고, 앱이 앞에 있을 때.
    func onWebScreenVisibilityChange(_ action: @escaping (Bool) -> Void) -> some View {
        modifier(WebScreenVisibility(action: action))
    }
}

private struct WebScreenVisibility: ViewModifier {
    let action: (Bool) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isTabSelected) private var isTabSelected
    @State private var isOnScreen = false

    private var isVisible: Bool {
        isOnScreen && isTabSelected && scenePhase == .active
    }

    func body(content: Content) -> some View {
        content
            .onAppear { isOnScreen = true }
            .onDisappear { isOnScreen = false }
            .onChange(of: isVisible, initial: true) { _, isVisible in action(isVisible) }
    }
}
