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
import Data

enum AppConfigurator {

    /// 앱 시작 시 한 번 호출되는 진입점.
    /// 각 SDK 초기화는 멱등하므로 재호출에도 안전하지만, 비용을 줄이기 위해 단일 호출을 권장한다.
    static func configureExternalSDKs() {
        clearKeychainOnFreshInstallIfNeeded()
        configureGoogleSignIn()
        configureKakaoSDK()
    }

    // MARK: - First-Launch Cleanup

    /// iOS Keychain은 앱 삭제 시 자동으로 비워지지 않는다. UserDefaults는 비워지므로,
    /// "한 번이라도 실행한 적이 있는가" 플래그를 UserDefaults에 두고 첫 실행이면 Keychain을 정리한다.
    /// 재설치 시 잔존 토큰으로 인해 의도치 않은 인증 요청이 나가는 것을 막는다.
    private static func clearKeychainOnFreshInstallIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Keys.hasLaunchedBefore) else { return }
        DefaultTokenStorage().clear()
        defaults.set(true, forKey: Keys.hasLaunchedBefore)
    }

    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    // MARK: - SDK Initializers

    /// Firebase plist의 `CLIENT_ID`가 아니라 Info.plist `GIDClientID`(Secrets.xcconfig `GOOGLE_CLIENT_ID`)에서 읽는다.
    /// Debug · Beta가 쓰는 dev Firebase 프로젝트 plist에는 `CLIENT_ID`가 없고, 구글 로그인은 구성과 관계없이 같은 OAuth 클라이언트를 쓴다(#423).
    private static func configureGoogleSignIn() {
        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientId.hasPrefix(".") else {
            // 빌드/배포 시점 환경 설정 누락(GOOGLE_CLIENT_ID가 비면 접미사만 남는다). 디버그 단서로 즉시 fail.
            fatalError("GIDClientID is not set in Info.plist (GOOGLE_CLIENT_ID missing)")
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
