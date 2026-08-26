//
//  DeepLink.swift
//  Presentation
//
//  외부에서 앱으로 들어오는 유니버설 링크(공유 링크)를 앱 내부 라우팅 값으로 바꾼다.
//  커스텀 URL scheme은 사용하지 않는다 — 링크 하나가 웹/앱 어디서나 같은 글을 가리켜야 하고,
//  앱 미설치 사용자는 그대로 웹으로 열려야 하기 때문이다.
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

    /// 들어온 URL이 우리가 처리하는 딥링크인지 판별한다. 아니면 `nil` — 앱만 열리고 화면은 그대로 둔다.
    ///
    /// 호스트 검증은 세션 쿠키를 가진 웹뷰에 남의 도메인이 실리는 것을 막기 위한 것으로,
    /// `OPEN_SUBVIEW`의 동일 origin 검사와 같은 목적이다.
    static func parse(_ url: URL) -> DeepLink? {
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
