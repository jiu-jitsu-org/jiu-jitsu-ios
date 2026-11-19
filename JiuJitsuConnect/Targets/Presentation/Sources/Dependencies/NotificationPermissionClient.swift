//
//  NotificationPermissionClient.swift
//  Presentation
//
//  시스템 알림 권한의 지금 상태를 읽는다(#243).
//  권한 창은 FirebaseClient.requestPermission이 띄우고, 허용되면 FCMAppInfoSync가 푸시 등록과 FCM 토큰 발급을 잇는다.
//

import ComposableArchitecture
import UserNotifications

public struct NotificationPermissionClient: Sendable {
    public enum Status: Equatable, Sendable {
        /// 아직 한 번도 묻지 않음 — 지금 물으면 시스템 권한 창이 뜬다.
        case notDetermined
        case granted
        /// 거절했거나 기기 설정에서 껐음 — 앱이 다시 물을 수 없고 설정 앱에서만 켤 수 있다.
        case denied
    }

    public var status: @Sendable () async -> Status

    public init(status: @Sendable @escaping () async -> Status) {
        self.status = status
    }
}

extension NotificationPermissionClient: DependencyKey {
    public static let liveValue = NotificationPermissionClient(
        status: {
            switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
            case .notDetermined:
                return .notDetermined
            case .authorized, .provisional, .ephemeral:
                return .granted
            case .denied:
                return .denied
            @unknown default:
                return .denied
            }
        }
    )

    public static let testValue = NotificationPermissionClient(
        status: unimplemented("NotificationPermissionClient.status", placeholder: .denied)
    )

    public static let previewValue = NotificationPermissionClient(
        status: { .notDetermined }
    )
}

/// '관심 대회 알림'을 켠 뒤 본 기기 알림 상태(#257 · #395). 웹의 '알림 받기' · 상세 종과 설정 › 알림이 같이 쓴다.
public enum DeviceNotificationCheck: Equatable, Sendable {
    /// 이미 허용 — 할 일이 없다.
    case granted
    /// 방금 시스템 권한 창에서 허용 — 푸시 등록 · FCM 토큰 등록을 잇는다.
    case grantedNow
    /// 방금 권한 창에서 거절했거나, 전에 거절 · 기기 설정에서 끔 — 앱이 다시 물을 수 없어 설정 앱으로 안내한다.
    case denied

    var isEnabled: Bool { self != .denied }

    /// 지금 상태를 본다. 한 번도 묻지 않았으면 iOS 설정에 알림 줄조차 없으니 시스템 권한 창을 띄우고 답을 기다린다.
    static func current() async -> Self {
        @Dependency(\.notificationPermissionClient) var notificationPermissionClient
        @Dependency(\.firebaseClient) var firebaseClient
        switch await notificationPermissionClient.status() {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return await firebaseClient.requestPermission() ? .grantedNow : .denied
        }
    }
}

extension DependencyValues {
    public var notificationPermissionClient: NotificationPermissionClient {
        get { self[NotificationPermissionClient.self] }
        set { self[NotificationPermissionClient.self] = newValue }
    }
}
