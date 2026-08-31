//
//  DeepLink.swift
//  Presentation
//
//  외부에서 앱으로 들어오는 공유 링크를 앱 내부 라우팅 값으로 바꾼다.
//
//  1차 경로는 유니버설 링크다 — 링크 하나가 웹/앱 어디서나 같은 글을 가리키고,
//  앱 미설치 사용자는 그대로 웹으로 열려야 하기 때문이다.
//  다만 iOS는 이미 보고 있는 페이지와 같은 도메인의 링크를 탭했을 때는 유니버설 링크를
//  발동시키지 않아, 웹 페이지 안의 '앱 열기' 버튼(FE#72)은 그 경로로 앱을 열 수 없다(#25 실측).
//  그래서 커스텀 스킴을 보조 전송 수단으로 둔다. 목적지는 여전히 같은 https URL이므로
//  검증도 그 URL에 그대로 적용해 두 경로가 한 벌의 규칙만 공유하게 한다.
//

import CoreKit
import Foundation

/// 앱이 처리하는 딥링크 종류.
public enum DeepLink: Equatable, Sendable {
    /// 게시글 상세(`/community/{id}`).
    /// `url`은 쿼리까지 포함한 원본 링크 그대로 — 상세 웹뷰가 그대로 로드해 웹이 해석한다.
    case communityPost(url: URL, postId: String)

    public var url: URL {
        switch self {
        case let .communityPost(url, _):
            return url
        }
    }
}

enum DeepLinkParser {
    /// 게시글 상세 경로의 첫 세그먼트. 웹 라우트 `src/app/community/[id]`와 1:1로 대응한다.
    private static let communitySegment = "community"

    /// 웹 페이지 안의 '앱 열기' 버튼용 커스텀 스킴.
    /// Info.plist `CFBundleURLTypes`(Project.swift)·웹(FE#72)에 등록된 값과 반드시 같아야 한다.
    private static let customScheme = "bjjossapp"

    /// 커스텀 스킴이 원본 https 링크를 싣는 쿼리 파라미터 이름.
    private static let payloadQueryName = "url"

    /// 들어온 URL이 우리가 처리하는 딥링크인지 판별한다. 아니면 `nil` — 앱만 열리고 화면은 그대로 둔다.
    static func parse(_ url: URL) -> DeepLink? {
        guard let scheme = url.scheme?.lowercased() else {
            Log.trace("딥링크 무시(스킴 없음): \(url.absoluteString)", category: .system, level: .info)
            return nil
        }

        switch scheme {
        case "https":
            return parseWebLink(url)

        case customScheme:
            // 스킴은 전송 수단일 뿐이고, 실제 검증은 안에 실린 https URL에 그대로 적용한다.
            // 이렇게 해야 호스트 검증과 "원본 URL 그대로 전달" 원칙이 한 곳에만 남는다.
            guard let inner = unwrapCustomScheme(url) else { return nil }
            return parseWebLink(inner)

        default:
            // 카카오·구글 로그인 스킴은 App 타겟의 onOpenURL이 처리한다.
            Log.trace("딥링크 무시(지원하지 않는 스킴): \(url.absoluteString)", category: .system, level: .info)
            return nil
        }
    }

    /// `bjjossapp://open?url=<퍼센트 인코딩된 https URL>` 에서 원본 링크를 꺼낸다.
    ///
    /// `URLComponents.queryItems`가 값을 퍼센트 디코딩해 주므로 별도 디코딩은 하지 않는다.
    private static func unwrapCustomScheme(_ url: URL) -> URL? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let raw = components.queryItems?.first(where: { $0.name == payloadQueryName })?.value,
            let inner = URL(string: raw)
        else {
            Log.trace("딥링크 무시(커스텀 스킴 payload 없음): \(url.absoluteString)", category: .system, level: .error)
            return nil
        }
        return inner
    }

    /// https 링크 검증. 유니버설 링크와 커스텀 스킴이 함께 통과하는 유일한 관문이다.
    ///
    /// 호스트 검증은 세션 쿠키를 가진 웹뷰에 남의 도메인이 실리는 것을 막기 위한 것으로,
    /// `OPEN_SUBVIEW`의 동일 origin 검사와 같은 목적이다.
    /// 여기서 https를 다시 확인하므로 커스텀 스킴 중첩(`bjjossapp://open?url=bjjossapp://...`)도 함께 걸러진다.
    private static func parseWebLink(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == "https" else {
            Log.trace("딥링크 무시(https 아님): \(url.absoluteString)", category: .system, level: .info)
            return nil
        }
        guard
            let host = url.host?.lowercased(),
            WebEnvironment.allowedHosts.contains(host)
        else {
            Log.trace("딥링크 무시(허용되지 않은 호스트): \(url.absoluteString)", category: .system, level: .error)
            return nil
        }

        // pathComponents는 선행 "/"를 원소로 포함하므로 걸러낸 뒤 세그먼트 수를 본다.
        let segments = url.pathComponents.filter { $0 != "/" }
        guard
            segments.count == 2,
            segments[0] == communitySegment
        else {
            Log.trace("딥링크 무시(지원하지 않는 경로): \(url.absoluteString)", category: .system, level: .info)
            return nil
        }

        // 글쓰기(`/community/write`) 같은 비-상세 라우트를 걸러내기 위해 id는 숫자만 허용한다.
        let postId = segments[1]
        guard !postId.isEmpty, postId.allSatisfy(\.isNumber) else {
            Log.trace("딥링크 무시(게시글 id 형식 아님): \(url.absoluteString)", category: .system, level: .info)
            return nil
        }

        return .communityPost(url: url, postId: postId)
    }
}
