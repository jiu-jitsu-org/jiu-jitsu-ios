//
//  AppTabFeature+NotificationPrompt.swift
//  Presentation
//
//  첫 글 · 댓글을 올린 뒤 알림 권한을 묻기 전 한 줄 안내(#333). 어느 탭의 웹에서 올렸든 AppTab이 한곳에서 정한다.
//  열린 설정 › 알림 다시 읽기(#281), 앱을 쓰는 중 도착한 알림으로 새 알림 점 다시 조회(#394)도 여기 둔다.
//

import ComposableArchitecture
import Foundation

extension AppTabFeature {
    public enum NotificationPromptAction: Sendable {
        case allowTapped
        case laterTapped
        // 내려 닫기 — [나중에]와 같이 미룬다
        case dismissed
    }

    /// 글 · 댓글을 올린 뒤 알림 권한 안내를 띄울지 정한다.
    /// 아직 묻지 않았을 때만 — 허용했으면 할 일이 없고, 거절했으면 시스템 창을 다시 띄울 수 없다(설정 › 알림 배너가 안내).
    /// '나중에'로 미뤘으면 7일 동안, 3번 미뤘으면 더 띄우지 않는다.
    func promptNotificationPermissionIfNeeded(_ state: State) -> Effect<Action> {
        guard !state.authInfo.isGuest, !state.isNotificationPromptPresented else { return .none }
        @Dependency(\.notificationPromptClient) var notificationPromptClient
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        return .run { [now] send in
            guard
                await notificationPermissionClient.status() == .notDetermined,
                notificationPromptClient.canPrompt(now)
            else { return }
            // 글쓰기 화면이 닫히고 댓글 키보드가 내려간 뒤에 띄운다.
            try await clock.sleep(for: .milliseconds(700))
            await send(.internal(.presentNotificationPrompt))
        }
        .cancellable(id: CancelID.notificationPermission, cancelInFlight: true)
    }

    /// 다른 알럿 · 시트 · 덮개가 떠 있으면 이번엔 건너뛴다 — 나중에 횟수에도 넣지 않는다.
    /// 상세 모달이 떠 있으면 탭 화면에 붙인 시트가 모달 아래라 보이지 않는다.
    static func presentNotificationPrompt(into state: inout State) -> Effect<Action> {
        guard
            !state.authInfo.isGuest,
            state.loginCover == nil,
            state.home.detailCover == nil,
            !state.isLoginPromptPresented,
            !state.isDeviceNotificationAlertPresented,
            state.home.pendingConfirmDialog == nil,
            state.home.pendingSelectSheet == nil
        else { return .none }
        state.isNotificationPromptPresented = true
        return .none
    }

    func reduceNotificationPrompt(_ action: NotificationPromptAction, into state: inout State) -> Effect<Action> {
        switch action {
        case .allowTapped:
            // 시스템 권한 창. 허용하면 관심 대회 알림과 같이 푸시 등록 · FCM 토큰 발급 · 서버 등록을 잇는다.
            state.isNotificationPromptPresented = false
            return .run { send in
                if await firebaseClient.requestPermission() {
                    await send(.internal(.notificationPermissionGranted))
                }
            }
            .cancellable(id: CancelID.notificationPermission, cancelInFlight: true)

        case .laterTapped, .dismissed:
            // [알림 받기]로 이미 닫았으면 내려 닫힘 신호가 한 번 더 와도 미루지 않는다.
            guard state.isNotificationPromptPresented else { return .none }
            state.isNotificationPromptPresented = false
            @Dependency(\.notificationPromptClient) var notificationPromptClient
            @Dependency(\.date.now) var now
            return .run { [now] _ in notificationPromptClient.snooze(now) }
        }
    }
}

// MARK: - 알림 설정 · 앱 사용 중 알림

extension AppTabFeature {
    /// 웹이 관심 대회 알림을 서버에 저장함(#281) → MY 스택에 설정 › 알림이 열려 있으면 서버 값을 다시 읽힌다.
    static func refreshOpenNotificationSetting(_ state: State) -> Effect<Action> {
        for id in state.myPage.path.ids {
            guard
                case let .settings(settings)? = state.myPage.path[id: id],
                case .notificationSetting? = settings.destination
            else { continue }
            return .send(.myPage(.path(.element(
                id: id,
                action: .settings(.destination(.presented(.notificationSetting(.settingRefreshRequested))))
            ))))
        }
        return .none
    }

    /// 앱을 쓰는 중 도착한 알림을 구독한다(#394). 배너만 뜨고 종의 새 알림 점은 그대로라 받을 때마다 다시 조회한다.
    func observeNotificationArrivals() -> Effect<Action> {
        .run { send in
            for await _ in pushNotificationClient.arrivals() {
                await send(.internal(.notificationArrived))
            }
        }
        .cancellable(id: CancelID.notificationArrivalObserver, cancelInFlight: false)
    }

    /// 홈에 새 알림 점을 다시 조회시킨다. 대회 탭 종도 같은 값을 그려 함께 켜진다(#258).
    /// 게스트는 홈이 조회하지 않고, 로그아웃 중엔 이전 계정의 알림이라 조회하지 않는다.
    static func refreshUnreadOnArrival(_ state: State) -> Effect<Action> {
        guard !state.authInfo.isGuest, !state.isLoggingOut else { return .none }
        return .send(.home(.unreadNotificationRefreshRequested))
    }
}
