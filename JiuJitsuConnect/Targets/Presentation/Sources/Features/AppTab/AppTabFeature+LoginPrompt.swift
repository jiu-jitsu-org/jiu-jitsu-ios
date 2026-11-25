//
//  AppTabFeature+LoginPrompt.swift
//  Presentation
//
//  게스트 로그인 안내 알럿의 이유별 문구(#392). 이유 → 문구는 이 파일 한 곳에서만 고친다.
//

import Foundation

extension AppTabFeature {
    /// 웹이 `AUTH_LOGIN_PROMPT`에 실은 이유. 사전에 없는 값 · 이유 없음(이유를 싣기 전에 배포된 웹)은 nil이라 기본 문구가 뜬다.
    static func loginReason(from webReason: String?) -> AnalyticsEvent.LoginReason? {
        webReason.flatMap(AnalyticsEvent.LoginReason.init(rawValue:))
    }

    /// 무엇을 하려다 막혔는지 제목으로 알려 로그인할 이유를 분명히 한다. 본문 · 버튼은 이유와 관계없이 같다.
    /// 이유별 제목은 한 줄로 짧게 — 가장 좁은 지원 기기(375pt)의 알럿 폭에도 줄바꿈 없이 들어가는 길이로 둔다.
    static func loginPromptTitle(for reason: AnalyticsEvent.LoginReason?) -> String {
        switch reason {
        case .like: "로그인하고 좋아요를 눌러 보세요"
        case .save: "로그인하고 글을 저장해 보세요"
        case .write: "로그인하고 첫 글을 써 보세요"
        case .comment: "로그인하고 댓글을 남겨 보세요"
        case .reply: "로그인하고 답글을 남겨 보세요"
        case .vote: "로그인하고 투표해 보세요"
        case .interest: "로그인하면 마감 전날 알려 드려요"
        // 대회 알림뿐 아니라 글 · 밸런스 '알림 받기'(401 뒤)에서도 와서 대회에 묶지 않는다.
        case .alert: "로그인하고 알림을 받아 보세요"
        case .interestFilter: "로그인하고 관심 대회만 보세요"
        case .infoReport: "로그인하고 정보를 알려 주세요"
        case .record: "로그인하고 기록을 남겨 보세요"
        case .report: "로그인하고 신고해 주세요"
        case .block: "로그인하면 차단할 수 있어요"
        case .profile: "로그인하고 프로필을 보세요"
        // 만료는 따로 할 일이 없어 기본 문구(웹 401 뒤 안내). my_tab은 앱 MY 탭 값이라 이 알럿으로 오지 않는다.
        case .sessionExpired, .myTab, nil: "로그인하고 더 많은\n기능을 이용해보세요"
        }
    }

    static let loginPromptMessage = "커뮤니티 참여와 프로필 설정이 가능해요."
}
