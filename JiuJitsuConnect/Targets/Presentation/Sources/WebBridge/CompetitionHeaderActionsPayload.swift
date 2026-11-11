//
//  CompetitionHeaderActionsPayload.swift
//  Presentation
//

import Foundation
import CoreKit

// MARK: - COMPETITION_HEADER_ACTIONS Payload

/// `COMPETITION_HEADER_ACTIONS` 페이로드(#266) — 대회 목록 웹이 지금 어떤 상태로 그려져 있는지.
/// 앱 대회 탭 머리줄의 ♡·달력 버튼을 이 값으로 그린다.
public struct CompetitionHeaderActionsPayload: Equatable, Sendable {
    public enum Mode: String, Sendable {
        case list
        case calendar
    }

    /// '관심 대회만 보기'가 켜져 있는지.
    public let interestedOnly: Bool
    /// 지금 보이는 모양(목록/달력).
    public let mode: Mode

    public init(interestedOnly: Bool, mode: Mode) {
        self.interestedOnly = interestedOnly
        self.mode = mode
    }

    /// 웹이 보낸 값을 검사해 만든다. 둘 중 하나라도 알 수 없으면 버튼을 엉뚱한 모양으로 그리게 되므로 nil —
    /// 받는 쪽은 무시하고 직전 상태를 둔다.
    init?(payload: [String: Any]?) {
        guard
            let interestedOnly = payload?["interestedOnly"] as? Bool,
            let mode = (payload?["mode"] as? String).flatMap(Mode.init(rawValue:))
        else {
            Log.trace("COMPETITION_HEADER_ACTIONS payload 필수 필드 누락/형식 오류", category: .network, level: .error)
            return nil
        }
        self.init(interestedOnly: interestedOnly, mode: mode)
    }
}

// MARK: - COMPETITION_HEADER_ACTION (네이티브 → 웹)

/// `COMPETITION_HEADER_ACTION`으로 웹에 넘기는 머리줄 버튼 탭. 켜고 끄는 판단(비로그인 안내 포함)은 웹이 한다.
public enum CompetitionHeaderAction: String, Equatable, Sendable {
    case toggleInterested
    case toggleMode
}
