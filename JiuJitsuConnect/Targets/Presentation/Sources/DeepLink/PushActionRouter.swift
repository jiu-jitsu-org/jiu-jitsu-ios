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
    // 관심 대회 마감 전날 알림(#256). data는 웹 대회 slug → `/competition/{slug}`(대회 탭 스택에 상세).
    // 백엔드가 아직 정하지 않은 임시 이름이다 — 백엔드 PushActionType 값이 정해지면 그 값과 똑같이 맞춘다.
    /// 얼리버드 접수 마감 전날
    case competitionEarlyBirdDeadline = "COMPETITION_EARLY_BIRD_DEADLINE"
    /// 접수 마감 전날
    case competitionRegistrationDeadline = "COMPETITION_REGISTRATION_DEADLINE"
}

/// 푸시·알림함이 실어 보내는 이동 정보. 서버가 새 값을 추가해도 구버전 앱이 죽지 않도록
/// 여기서는 원본 문자열만 보관하고 해석은 `PushActionRouter`에서 한다.
public struct PushActionPayload: Equatable, Sendable {
    /// 서버가 보낸 `type`/`actionType` 원문. 미지원 값도 로그를 위해 그대로 둔다.
    public let actionType: String?
    /// 대상 contentId 문자열(대회 마감 알림은 대회 slug).
    public let data: String?

    public init(actionType: String?, data: String?) {
        self.actionType = actionType
        self.data = data
    }

    /// FCM 데이터 메시지는 `putData`한 키가 `userInfo` 최상위에 문자열로 실린다(`FcmPushService`).
    public init(userInfo: [AnyHashable: Any]) {
        self.init(
            actionType: userInfo[Keys.type] as? String,
            data: userInfo[Keys.data] as? String
        )
    }

    private enum Keys {
        static let type = "type"
        static let data = "data"
    }
}

enum PushActionRouter {
    /// payload를 딥링크용 https URL로 바꾼다. 미지원 `actionType`·빈 `data`는 `nil` — 앱만 열리고
    /// 화면은 그대로 둔다(= 커뮤니티 홈). 여기서 만든 URL은 `DeepLinkParser`를 다시 통과하므로
    /// 게시글·밸런스 게임의 contentId 형식 검증은 그쪽에 맡긴다. 대회 slug는 파서가 형식을 보지 않아 여기서 검사한다.
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
            url = origin
                .appending(path: DeepLinkParser.communitySegment)
                .appending(path: contentId)
        case .balanceDetail:
            url = origin
                .appending(path: DeepLinkParser.communitySegment)
                .appending(path: DeepLinkParser.balanceSegment)
                .appending(path: contentId)
        case .competitionEarlyBirdDeadline, .competitionRegistrationDeadline:
            // slug는 숫자 id가 아니라 파서가 형식을 보지 않으므로, 다른 경로로 새는 값은 여기서 거른다.
            guard DeepLinkParser.isCompetitionSlug(contentId) else {
                Log.trace("푸시 액션 무시(대회 slug 형식 아님): \(rawType) \(contentId)", category: .system, level: .error)
                return nil
            }
            url = origin
                .appending(path: DeepLinkParser.competitionSegment)
                .appending(path: contentId)
        }
        Log.trace("푸시 액션 → 딥링크: \(rawType) \(contentId) → \(url.absoluteString)", category: .system, level: .info)
        return url
    }
}
