//
//  WebEnvironment.swift
//  Presentation
//
//  웹뷰가 로드하는 도메인 설정(Info.plist)을 읽는 단일 창구.
//  값은 Secrets.xcconfig의 WEB_URL_DEV / WEB_URL_PROD에서 출발해
//  Project.swift가 구성별(Debug·Beta → dev, Release → prod)로 WEB_URL에 확정한다.
//

import Foundation

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

    static func string(forKey key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
