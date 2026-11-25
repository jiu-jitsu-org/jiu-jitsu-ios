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
    /// 제목은 두 줄까지라(`AppAlertView`) 한 줄이 넘는 문구는 뜻이 끊기지 않는 곳에서 직접 줄을 바꾼다.
    static func loginPromptTitle(for reason: AnalyticsEvent.LoginReason?) -> String {
        switch reason {
        case .like: "로그인하면 좋아요를\n남길 수 있어요"
        case .save: "로그인하면 글을 저장해 두고\n다시 볼 수 있어요"
        case .write: "로그인하고 첫 글을\n남겨 보세요"
        case .comment: "로그인하고 댓글로\n이야기해 보세요"
        case .reply: "로그인하고 답글로\n대화를 이어 가 보세요"
        case .vote: "로그인하고 투표해 보세요"
        case .interest, .alert: "로그인하면 관심 대회\n마감 전날 알려 드려요"
        case .interestFilter: "로그인하면 관심 대회만\n모아 볼 수 있어요"
        case .infoReport: "로그인하고 잘못된 정보를\n알려 주세요"
        case .record: "로그인하면 내 기록에\n남길 수 있어요"
        case .report: "로그인하면 신고할 수 있어요"
        case .block: "로그인하면 차단을\n관리할 수 있어요"
        case .profile: "로그인하면 프로필을\n볼 수 있어요"
        // 만료는 따로 할 일이 없어 기본 문구(웹 401 뒤 안내). my_tab은 앱 MY 탭 값이라 이 알럿으로 오지 않는다.
        case .sessionExpired, .myTab, nil: "로그인하고 더 많은\n기능을 이용해보세요"
        }
    }

    static let loginPromptMessage = "커뮤니티 참여와 프로필 설정이 가능해요."
}
