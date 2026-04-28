//
//  AppConfigurator.swift
//  App
//
//  앱 진입점에서 외부 SDK·라이브러리 초기화를 일괄 담당한다.
//  `JiuJitsuConnectApp.init()` 한 곳에서만 호출되며, 각 SDK 초기화 절차의
//  순서·실패 처리 책임을 진입점 타입 밖으로 분리하여 테스트 가능성과 가독성을 확보한다.
//

import Foundation
import GoogleSignIn
import KakaoSDKCommon

enum AppConfigurator {

    /// 앱 시작 시 한 번 호출되는 진입점.
    /// 각 SDK 초기화는 멱등하므로 재호출에도 안전하지만, 비용을 줄이기 위해 단일 호출을 권장한다.
    static func configureExternalSDKs() {
        configureGoogleSignIn()
        configureKakaoSDK()
    }

    // MARK: - SDK Initializers

    private static func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let clientId = NSDictionary(contentsOfFile: path)?["CLIENT_ID"] as? String else {
            // 빌드/배포 시점 환경 설정 누락. 디버그 단서로 즉시 fail.
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    private static func configureKakaoSDK() {
        guard let kakaoAppKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String else {
            fatalError("KAKAO_NATIVE_APP_KEY is not set in Info.plist")
        }
        KakaoSDK.initSDK(appKey: kakaoAppKey)
    }
}
