//
//  WebSessionCookie.swift
//  Presentation
//
//  하이브리드 세션 동기화 — 네이티브 accessToken을 FE 세션 쿠키로 웹뷰 쿠키 저장소에 주입한다.
//
//  WHY: FE 인증은 httpOnly 세션 쿠키(`oss_session`) 기반이다. 웹은 AUTH_LOGIN_SUCCESS를 받으면
//  클라이언트에서 `/api/auth/session`을 호출해 그 쿠키를 굽지만, 이는 페이지 로드 "이후"라
//  서브뷰처럼 SSR로 새로 여는 라우트(`/community/write` 등)는 첫 요청 시점에 쿠키가 없어
//  서버가 로그아웃 상태로 렌더한다. 또 WKWebView 인스턴스 간 fetch로 구운 쿠키 동기화는 보장되지
//  않는다. 따라서 네이티브가 웹뷰 로드 "전에" 동일한 세션 쿠키를 공유 저장소에 심어, 모든
//  웹뷰(메인·서브뷰)의 첫 SSR 네비게이션부터 인증되게 한다.
//
//  계약: 쿠키 스펙은 FE `src/config/auth.ts` / `src/shared/lib/auth/session-cookie.ts`와 일치해야 한다.
//

import Foundation
import WebKit
import CoreKit

enum WebSessionCookie {
    /// FE 세션 쿠키 이름. FE `SESSION_COOKIE_NAME`("oss_session")과 1:1로 맞춘다.
    static let name = "oss_session"

    /// accessToken을 세션 쿠키로 만들어 공유 쿠키 저장소에 주입한다.
    /// SSR이 첫 요청부터 인증되도록 웹뷰 `load` 직전에 await한다. accessToken이 없으면(게스트)
    /// 아무것도 심지 않는다. (로그아웃 시 쿠키 제거는 FE가 DELETE /api/auth/session으로 처리)
    @MainActor
    static func sync(accessToken: String?, for url: URL, into store: WKHTTPCookieStore) async {
        guard
            let accessToken,
            let host = url.host,
            let cookie = make(accessToken: accessToken, host: host, secure: url.scheme == "https")
        else { return }
        await store.setCookie(cookie)
    }

    private static func make(accessToken: String, host: String, secure: Bool) -> HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: accessToken,
            .domain: host,
            .path: "/",
            .sameSitePolicy: HTTPCookieStringPolicy.sameSiteLax,
        ]
        // https일 때만 Secure. (IP/http 도메인 변경 테스트에서는 Secure 쿠키가 저장 안 되므로 제외)
        if secure {
            properties[.secure] = "TRUE"
        }
        // 토큰 exp를 쿠키 만료로 맞춰, 서버가 환산한 수명과 정합을 유지한다.
        if let exp = JWTDecoder.expiry(of: accessToken) {
            properties[.expires] = Date(timeIntervalSince1970: TimeInterval(exp))
        }
        return HTTPCookie(properties: properties)
    }
}
