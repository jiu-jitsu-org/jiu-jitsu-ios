//
//  AppDelegate.swift
//  App
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import Presentation

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
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
