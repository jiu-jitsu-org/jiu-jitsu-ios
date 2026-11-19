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

    /// 앱 웹뷰가 문서를 띄우고 브리지를 주고받는 호스트. 유니버설 링크 호스트에
    /// Debug · Beta의 테스트용 도메인 오버라이드(IP · http 포함) 주소를 더한다(딥링크 검증의 `allowedHosts`는 그대로 둔다).
    static var webViewHosts: Set<String> {
        var hosts = allowedHosts
#if DEBUG || BETA
        if let host = debugOverrideURL()?.host?.lowercased() {
            hosts.insert(host)
        }
#endif
        return hosts
    }

    /// 앱 웹뷰가 그대로 띄워도 되는 주소인지 — http(s)이고 앱 웹 호스트일 때만. 세션 쿠키 · 아웃바운드 메시지도 이때만 넣는다.
    static func isAllowedWebURL(_ url: URL?) -> Bool {
        guard let url, let scheme = url.scheme, let host = url.host else { return false }
        return isAllowed(scheme: scheme, host: host)
    }

    /// 브리지 메시지를 보낸 프레임이 OSS 웹(앱 웹 호스트)의 메인 프레임인지. 아니면(iframe · 바깥 문서) 메시지를 받지 않는다.
    @MainActor
    static func isOSSFrame(_ frame: WKFrameInfo) -> Bool {
        frame.isMainFrame && isAllowed(scheme: frame.securityOrigin.protocol, host: frame.securityOrigin.host)
    }

    private static func isAllowed(scheme: String, host: String) -> Bool {
        let scheme = scheme.lowercased()
        return (scheme == "https" || scheme == "http") && webViewHosts.contains(host.lowercased())
    }

    /// 메인 프레임 이동을 어디서 열지.
    enum MainFrameRoute: Equatable {
        /// 웹뷰에서 그대로 연다(앱 웹 주소 · 빈 문서).
        case webView
        /// 앱 위 브라우저로 연다(바깥 http(s) 주소). 다른 앱이 맡는 유니버설 링크면 그 앱으로.
        case inAppBrowser
        /// 시스템에 넘긴다(전화 · 메일).
        case system
        /// 열지 않는다(그 밖 스킴).
        case blocked
    }

    /// 웹뷰 메인 프레임 이동의 갈 곳. iframe 이동에는 쓰지 않고, 새 창은 전화 · 메일 판정에만 쓴다.
    static func mainFrameRoute(for url: URL) -> MainFrameRoute {
        switch url.scheme?.lowercased() {
        case "https", "http":
            return isAllowedWebURL(url) ? .webView : .inAppBrowser
        case "tel", "mailto":
            return .system
        case "about":
            // 빈 문서는 바깥 내용을 싣지 않는다. 주소가 앱 웹이 아니라 토큰 · 아웃바운드 메시지는 넣지 않는다.
            return .webView
        default:
            return .blocked
        }
    }

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
