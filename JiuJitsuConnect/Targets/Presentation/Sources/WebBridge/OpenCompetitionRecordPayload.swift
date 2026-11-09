//
//  OpenCompetitionRecordPayload.swift
//  Presentation
//

import Foundation

// MARK: - OPEN_COMPETITION_RECORD Payload

/// `OPEN_COMPETITION_RECORD` 페이로드(#250). `competitionId`는 웹 대회 slug(문자열)라
/// 내 기록의 숫자 대회 id와 이어지지 않는다 — 이름·연도를 채우는 데만 쓴다.
public struct OpenCompetitionRecordPayload: Equatable, Sendable {
    public let competitionId: String
    public let name: String
    public let year: Int

    public init(competitionId: String, name: String, year: Int) {
        self.competitionId = competitionId
        self.name = name
        self.year = year
    }

    /// 웹이 보낸 값을 검사해 만든다. 이름·연도가 없으면 채울 값이 없어 빈 추가 화면만 뜨므로 nil.
    /// 연도는 정수·상식 범위만 받는다 — 터무니없는 값이면 연도 휠이 그 해까지 늘어난다.
    init?(payload: [String: Any]?) {
        let name = (payload?["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let currentYear = Calendar.current.component(.year, from: Date())
        guard
            let competitionId = payload?["competitionId"] as? String,
            !name.isEmpty,
            let yearNumber = payload?["year"] as? NSNumber,
            CFGetTypeID(yearNumber) != CFBooleanGetTypeID(),
            yearNumber.doubleValue == yearNumber.doubleValue.rounded(),
            case let year = yearNumber.intValue,
            (1990...(currentYear + 1)).contains(year)
        else {
            return nil
        }
        self.init(competitionId: competitionId, name: name, year: year)
    }
}
