//
//  HomeFeedFilter.swift
//  Presentation
//

import Foundation

// MARK: - OPEN_HOME_FEED Payload

/// `OPEN_HOME_FEED`로 홈 피드를 열 때 걸 필터(#437 · #480). 웹 피드 주소의 쿼리와 1:1이다(`/?competitionId=` · `/?categoryId=`).
public enum HomeFeedFilter: Equatable, Sendable {
    case competition(Int)
    case category(Int)

    /// 웹은 둘을 같이 보내지 않는다. 같이 오면 먼저 생긴 대회(#437)를 따른다. 숫자 · 숫자 문자열 둘 다 받는다.
    init?(payload: [String: Any]?) {
        if let competitionId = OpenCompetitionRecordPayload.parseCompetitionId(payload?["competitionId"]) {
            self = .competition(competitionId)
        } else if let categoryId = OpenCompetitionRecordPayload.parseCompetitionId(payload?["categoryId"]) {
            self = .category(categoryId)
        } else {
            return nil
        }
    }

    var logSummary: String {
        switch self {
        case let .competition(id): "competitionId=\(id)"
        case let .category(id): "categoryId=\(id)"
        }
    }
}
