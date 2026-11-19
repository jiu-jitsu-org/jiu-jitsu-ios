//
//  PushActionRouter.swift
//  Presentation
//
//  푸시 payload(`type`·`data`)와 알림함 응답(`actionType`·`data`)을 목적지 URL로 바꾼다.
//
//  푸시 탭을 위한 별도 라우팅 경로를 두지 않고, 공유 링크와 같은 https URL로 변환해
//  기존 딥링크 파이프라인(DeepLinkParser → AppFeature → CommunityFeature)에 그대로 태운다.
//  비로그인·콜드 스타트 보류(pendingDeepLink), 최상단 중복 상세 제거 같은 처리를 다시 만들지
//  않기 위해서다(#28). 두 payload는 값 규약이 같으므로(backend#134·#137) 변환기도 하나만 둔다.
//

import CoreKit
import Foundation

/// 푸시·알림함 탭 시 이동할 화면. 백엔드 `PushActionType`과 같은 값을 쓴다.
public enum PushActionType: String, Sendable {
    /// 게시글 상세 → `/community/{contentId}`
    case boardDetail = "BOARD_DETAIL"
    /// 밸런스 게임 상세 → `/community/balance/{contentId}`
    case balanceDetail = "BALANCE_DETAIL"
    /// 대회 상세 → `/competition/{id}`(대회 탭 스택에 상세). 관심 대회 마감 전날 알림이 쓴다(#256, #280).
    /// 알림 종류(얼리버드·접수 마감)는 서버 `pushType`이라 여기로 오지 않는다.
    case competitionDetail = "COMPETITION_DETAIL"
}

/// 푸시·알림함이 실어 보내는 이동 정보. 서버가 새 값을 추가해도 구버전 앱이 죽지 않도록
/// 여기서는 원본 문자열만 보관하고 해석은 `PushActionRouter`에서 한다.
public struct PushActionPayload: Equatable, Sendable {
    /// 서버가 보낸 `type`/`actionType` 원문. 미지원 값도 로그를 위해 그대로 둔다.
    public let actionType: String?
    /// 대상 contentId 문자열(대회 마감 알림은 대회 id).
    public let data: String?
    /// 알림 종류(서버 `FcmPushType` 이름, 예: `NEW_COMMENTS`). 분석 기록에만 쓴다(#427). 알림함 응답에는 없다.
    public let pushType: String?
    /// 댓글 알림(새 댓글 · 답글 · 댓글 좋아요)이 가리키는 댓글 id(backend#271). 글 상세 주소에 붙여 웹이 맨 위에 보인다(#436).
    public let commentId: String?
    /// 앱이 꺼져 있다 이 탭으로 켜졌다. 받을 화면이 아직 없어 릴레이가 보관했던 탭이다(`PushNotificationTapRelay`).
    public let isColdStart: Bool

    public init(
        actionType: String?,
        data: String?,
        pushType: String? = nil,
        commentId: String? = nil,
        isColdStart: Bool = false
    ) {
        self.actionType = actionType
        self.data = data
        self.pushType = pushType
        self.commentId = commentId
        self.isColdStart = isColdStart
    }

    /// 같은 탭을 콜드 스타트로 표시한 사본. 필드를 여기서만 나열해, 필드가 늘어도 콜드 경로에서 빠지지 않게 한다.
    func markedColdStart() -> Self {
        Self(actionType: actionType, data: data, pushType: pushType, commentId: commentId, isColdStart: true)
    }

    /// FCM 데이터 메시지는 `putData`한 키가 `userInfo` 최상위에 문자열로 실린다(`FcmPushService`).
    public init(userInfo: [AnyHashable: Any]) {
        self.init(
            actionType: userInfo[Keys.type] as? String,
            data: userInfo[Keys.data] as? String,
            pushType: userInfo[Keys.pushType] as? String,
            commentId: userInfo[Keys.commentId] as? String
        )
    }

    private enum Keys {
        static let type = "type"
        static let data = "data"
        static let pushType = "pushType"
        static let commentId = "commentId"
    }
}

enum PushActionRouter {
    /// payload를 딥링크용 https URL로 바꾼다. 미지원 `actionType`·빈 `data`는 `nil` — 앱만 열리고
    /// 화면은 그대로 둔다(= 커뮤니티 홈). 여기서 만든 URL은 `DeepLinkParser`를 다시 통과하므로
    /// 게시글·밸런스 게임의 contentId 형식 검증은 그쪽에 맡긴다. 대회 id는 주소에 붙이기 전에 여기서도 검사한다.
    static func makeURL(from payload: PushActionPayload) -> URL? {
        guard
            let rawType = payload.actionType,
            let actionType = PushActionType(rawValue: rawType.uppercased())
        else {
            Log.trace("푸시 액션 무시(지원하지 않는 type): \(payload.actionType ?? "nil")", category: .system, level: .info)
            return nil
        }
        guard let contentId = payload.data, !contentId.isEmpty else {
            Log.trace("푸시 액션 무시(data 없음): \(rawType)", category: .system, level: .error)
            return nil
        }
        guard let origin = URL(string: WebEnvironment.webURLString) else {
            Log.trace("WEB_URL is not set in Info.plist", category: .system, level: .error)
            return nil
        }

        let url: URL
        switch actionType {
        case .boardDetail:
            url = appendingCommentId(
                payload.commentId,
                to: origin
                    .appending(path: DeepLinkParser.communitySegment)
                    .appending(path: contentId)
            )
        case .balanceDetail:
            url = appendingCommentId(
                payload.commentId,
                to: origin
                    .appending(path: DeepLinkParser.communitySegment)
                    .appending(path: DeepLinkParser.balanceSegment)
                    .appending(path: contentId)
            )
        case .competitionDetail:
            // `/`·`..`처럼 다른 경로로 새는 값은 주소를 만들기 전에 거른다(파서도 같은 검사를 한다).
            guard DeepLinkParser.isCompetitionId(contentId) else {
                Log.trace("푸시 액션 무시(대회 id 형식 아님): \(rawType) \(contentId)", category: .system, level: .error)
                return nil
            }
            url = origin
                .appending(path: DeepLinkParser.competitionSegment)
                .appending(path: contentId)
        }
        Log.trace("푸시 액션 → 딥링크: \(rawType) \(contentId) → \(url.absoluteString)", category: .system, level: .info)
        return url
    }

    /// 댓글 알림이면 상세 주소에 `?commentId=`를 붙인다(#436). 숫자가 아니면 붙이지 않고 상세만 연다 —
    /// 웹도 무시하는 값이지만, 서버가 보낸 문자열을 주소에 그대로 싣지 않으려고 여기서 거른다.
    private static func appendingCommentId(_ commentId: String?, to url: URL) -> URL {
        guard let commentId, !commentId.isEmpty else { return url }
        guard DeepLinkParser.isNumericId(commentId) else {
            Log.trace("푸시 댓글 번호 무시(숫자 아님): \(commentId)", category: .system, level: .error)
            return url
        }
        return url.appending(queryItems: [URLQueryItem(name: DeepLinkParser.commentIdQueryName, value: commentId)])
    }
}
