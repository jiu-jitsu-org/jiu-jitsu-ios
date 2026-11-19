//
//  AppTabFeature+NotificationPrompt.swift
//  Presentation
//
//  첫 글 · 댓글을 올린 뒤 알림 권한을 묻기 전 한 줄 안내(#333). 어느 탭의 웹에서 올렸든 AppTab이 한곳에서 정한다.
//  관심 대회 알림을 켠 뒤 기기 알림 꺼짐 안내(#257 · #395), 열린 설정 › 알림 다시 읽기(#281), 앱을 쓰는 중 도착한 알림으로 새 알림 점 다시 조회(#394)도 여기 둔다.
//

import ComposableArchitecture
import CoreKit
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

// MARK: - 관심 대회 알림의 기기 알림 확인

extension AppTabFeature {
    /// 설정 › 알림에서 '관심 대회 알림'을 켰을 때 기기 알림 상태를 본다(#257). 설정 값은 서버에 있어(#281) 설정 화면이 저장하고, 여기서는 안내만 한다.
    /// 방금 권한 창에서 거절해도 앱이 다시 물을 수 없으니 설정 앱으로 안내한다(#395).
    func enableCompetitionAlerts() -> Effect<Action> {
        Log.trace("관심 대회 알림 켬: 설정", category: .view, level: .info)
        return .run { send in
            switch await DeviceNotificationCheck.current(permission: notificationPermissionClient, firebase: firebaseClient) {
            case .granted:
                return
            case .grantedNow:
                await send(.internal(.notificationPermissionGranted))
            case .denied:
                await send(.internal(.showDeviceNotificationAlert))
            }
        }
        .cancellable(id: CancelID.notificationPermission, cancelInFlight: true)
    }

    /// 웹이 관심 대회 알림을 켠 뒤 그 웹 화면이 본 기기 알림 상태(#395). 웹의 성공 토스트는 기기 알림이 켜져 있을 때만 뜨므로,
    /// 꺼져 있으면 이 안내가 유일한 답이다. 관심 등록마다 오므로 꺼짐 안내는 로그인 동안 한 번만 띄운다.
    /// 권한 창을 기다리는 사이 로그아웃 · 세션 만료로 게스트가 됐으면 띄우지 않는다.
    static func handleWebCompetitionAlertsCheck(_ check: DeviceNotificationCheck, into state: inout State) -> Effect<Action> {
        switch check {
        case .granted:
            return .none
        case .grantedNow:
            return .send(.internal(.notificationPermissionGranted))
        case .denied:
            guard !state.authInfo.isGuest, !state.didShowWebDeviceNotificationAlert else { return .none }
            state.didShowWebDeviceNotificationAlert = true
            state.isDeviceNotificationAlertPresented = true
            return .none
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
