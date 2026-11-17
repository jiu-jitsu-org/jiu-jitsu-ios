//
//  AppDelegate.swift
//  App
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging
import CoreKit
import Presentation

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        // Beta · Release가 같은 Firebase 앱 · 같은 버전 번호라 콘솔에서 구분하려고 넣는다. 회원 정보는 넣지 않는다(#374)
        Crashlytics.crashlytics().setCustomValue(Self.buildConfiguration, forKey: "build_config")
        #if DEBUG
        // 수집을 꺼도 크래시 보고서는 기기에 남아, 같은 기기에 Beta · Release를 깔면 그때 올라간다
        Crashlytics.crashlytics().deleteUnsentReports()
        #endif
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    private static var buildConfiguration: String {
        #if DEBUG
        return "debug"
        #elseif BETA
        return "beta"
        #else
        return "release"
        #endif
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Log.trace("[APNs] 디바이스 토큰 수신: \(deviceToken.map { String(format: "%02x", $0) }.joined())", category: .system, level: .info)
        Messaging.messaging().apnsToken = deviceToken
        FirebaseAPNSTokenBridge.deliverDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.trace("[APNs] 등록 실패: \(error)", category: .system, level: .error)
        FirebaseAPNSTokenBridge.deliverRegistrationFailure(error)
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// FCM 토큰을 로컬에 캐싱하고, 앱이 켜져 있는 동안 토큰이 바뀌었으면 TCA로 넘깁니다.
    /// 서버 등록은 로그인 여부를 아는 AppTab이 정합니다 — 여기서 바로 부르면 게스트·로그아웃 중에도 등록됩니다.
    /// Firebase는 delegate 설정 시 앱 매 실행마다 이 콜백을 발화하므로, 같은 토큰이면 넘기지 않습니다(#332).
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Log.trace("[FCM] 토큰 갱신: \(fcmToken)", category: .system, level: .info)
        DependencyContainer.shared.deliverFCMTokenRefresh(fcmToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 포그라운드 상태에서 알림을 수신했을 때 배너와 소리를 표시합니다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 배너만으로는 앱 안 종의 새 알림 점이 켜지지 않아, 앱 안으로도 알린다(#394).
        Log.trace("[Push] 앱 사용 중 알림 수신", category: .system, level: .info)
        DependencyContainer.shared.deliverForegroundNotification()
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림을 탭했을 때 payload(`type`·`data`)를 릴레이에 넘긴다. 해석·화면 이동은 AppFeature가 한다.
    /// 콜드 스타트에서는 스토어 구독보다 먼저 호출될 수 있는데, 릴레이가 보관했다가 전달한다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Log.trace("[Push] 알림 탭 수신: \(userInfo)", category: .system, level: .info)
        DependencyContainer.shared.deliverPushNotificationTap(PushActionPayload(userInfo: userInfo))
        completionHandler()
    }
}
