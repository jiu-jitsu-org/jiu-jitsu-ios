//
//  NotificationPermissionClient.swift
//  Presentation
//
//  시스템 알림 권한의 지금 상태를 읽는다(#243).
//  권한 창은 FirebaseClient.getFCMToken이 띄운다 — 허용되면 같은 흐름에서 푸시 등록과 FCM 토큰 발급까지 이어진다.
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

extension DependencyValues {
    public var notificationPermissionClient: NotificationPermissionClient {
        get { self[NotificationPermissionClient.self] }
        set { self[NotificationPermissionClient.self] = newValue }
    }
}
