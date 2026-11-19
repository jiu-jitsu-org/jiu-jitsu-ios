//
//  WebEnvironment.swift
//  Presentation
//
//  웹뷰가 로드하는 도메인 설정(Info.plist)을 읽는 단일 창구.
//  값은 Secrets.xcconfig의 WEB_URL_DEV / WEB_URL_PROD에서 출발해
//  Project.swift가 구성별(Debug·Beta → dev, Release → prod)로 WEB_URL에 확정한다.
//

import Foundation
import WebKit

enum WebEnvironment {
    /// 이 빌드 구성이 바라보는 웹 도메인. 오버라이드가 없을 때 커뮤니티 웹뷰가 로드한다.
    static var webURLString: String {
        string(forKey: "WEB_URL")
    }

    /// 유니버설 링크로 진입을 허용할 호스트 집합.
    ///
    /// 실제 게이트는 entitlements의 `applinks:`라 이 목록은 2차 방어선이다.
    /// DEBUG/BETA에서는 테스트용 딥링크 진입점으로 반대 환경(운영) 링크도 확인할 수 있어야 해
    /// 후보 도메인까지 함께 허용한다.
    static var allowedHosts: Set<String> {
        var candidates = [webURLString]
#if DEBUG || BETA
        candidates.append(contentsOf: [string(forKey: "DEBUG_WEB_URL_DEV"), string(forKey: "DEBUG_WEB_URL_PROD")])
#endif
        return Set(candidates.compactMap { URL(string: $0)?.host?.lowercased() })
    }

    /// 브리지 메시지를 보낸 프레임이 OSS 웹인지(#424). 분석 기록은 OSS 웹에서 온 것만 받는다.
    /// Debug · Beta는 테스트용 도메인 오버라이드(로컬 웹 등)로 띄운 웹도 받는다.
    @MainActor
    static func isOSSFrame(_ frame: WKFrameInfo) -> Bool {
        guard frame.isMainFrame else { return false }
        let host = frame.securityOrigin.host.lowercased()
        guard !host.isEmpty else { return false }
        if allowedHosts.contains(host) { return true }
#if DEBUG || BETA
        return debugOverrideURL()?.host?.lowercased() == host
#else
        return false
#endif
    }

    /// 테스트용 도메인 오버라이드(커뮤니티 설정에서 입력, UserDefaults).
    static let debugURLOverrideKey = "debug.community.webURLOverride"

#if DEBUG || BETA
    static func debugOverrideURL() -> URL? {
        guard
            let override = UserDefaults.standard.string(forKey: debugURLOverrideKey),
            !override.isEmpty
        else { return nil }
        return URL(string: override)
    }
#endif

    /// 웹뷰 User-Agent 끝에 붙이는 앱 표시(#370). 웹 서버가 앱 안인지 · 앱 버전을 첫 요청부터 안다
    /// (jiu-jitsu-frontend#510). 웹은 `OSSApp/`으로 찾으므로 형식을 바꾸면 웹과 같이 바꾼다.
    static var appUserAgentToken: String {
        let version = string(forKey: "CFBundleShortVersionString")
        return "OSSApp/\(version.isEmpty ? "0" : version) (iOS)"
    }

    /// 웹뷰 설정의 User-Agent 끝에 앱 표시를 덧붙인다.
    /// `applicationNameForUserAgent`의 기본값은 `Mobile/…` 토큰이라 덮어쓰면 웹이 모바일로 보지 못한다 — 뒤에 이어 붙인다.
    /// `customUserAgent`로 통째로 바꾸지 않는 것도 같은 이유(Safari와 같은 기본값을 지킴).
    @MainActor
    static func appendAppName(to configuration: WKWebViewConfiguration) {
        let base = configuration.applicationNameForUserAgent ?? ""
        configuration.applicationNameForUserAgent = base.isEmpty ? appUserAgentToken : "\(base) \(appUserAgentToken)"
    }

    static func string(forKey key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
