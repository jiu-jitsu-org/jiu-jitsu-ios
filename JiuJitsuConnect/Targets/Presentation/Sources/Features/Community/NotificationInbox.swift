//
//  NotificationInbox.swift
//  Presentation
//
//  알림함 웹(`/community/notifications`)의 주소. 홈과 대회 탭(#258)이 같은 알림함을 열고, 닫힐 때 새 알림 점을 다시 조회한다.
//

import Foundation

enum NotificationInbox {
    /// 숫자 id가 아니라 `DeepLinkParser`의 게시글 상세 경로로 오인되지 않는다.
    private static let path = "/\(DeepLinkParser.communitySegment)/notifications"

    /// 리스트 웹뷰와 같은 origin(테스트용 도메인 오버라이드 포함)에 알림함 경로를 붙인다.
    /// OPEN_SUBVIEW와 마찬가지로 세션 쿠키를 가진 웹뷰에 다른 origin이 실리지 않게 하기 위함이다.
    static func url(base: URL) -> URL? {
        URL(string: path, relativeTo: base)?.absoluteURL
    }

    /// 이 주소가 알림함인지 — 스택에서 닫힌 화면이 알림함이었는지 볼 때 쓴다.
    static func isInbox(_ url: URL) -> Bool {
        url.path() == path
    }
}
