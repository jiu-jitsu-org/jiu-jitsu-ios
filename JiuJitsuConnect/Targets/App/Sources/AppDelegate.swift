//
//  AppDelegate.swift
//  App
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Presentation

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ [APNs] 디바이스 토큰 수신: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
        FirebaseAPNSTokenBridge.deliverDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] 등록 실패: \(error)")
        FirebaseAPNSTokenBridge.deliverRegistrationFailure(error)
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// FCM 토큰을 로컬에 캐싱합니다.
    /// 서버 등록은 syncOnAppLaunch / syncAfterLoginSuccess 에서 단독으로 처리합니다.
    /// Firebase는 delegate 설정 시 앱 매 실행마다 이 콜백을 발화하므로
    /// 여기서 서버 호출을 하면 syncOnAppLaunch 와 중복 호출이 발생합니다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("🔄 [FCM] 토큰 갱신: \(fcmToken)")
        DependencyContainer.shared.configureFirebaseClient().cacheToken(fcmToken)
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
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림을 탭했을 때 payload를 기반으로 처리합니다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📬 [Push] 알림 탭 수신: \(userInfo)")
        completionHandler()
    }
}
