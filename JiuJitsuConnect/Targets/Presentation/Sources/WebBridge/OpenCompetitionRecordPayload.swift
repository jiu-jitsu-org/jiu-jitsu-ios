//
//  OpenCompetitionRecordPayload.swift
//  Presentation
//

import Foundation

// MARK: - OPEN_COMPETITION_RECORD Payload

/// `OPEN_COMPETITION_RECORD` 페이로드(#250). `competitionId`는 서버 대회 id(숫자, #281)라
/// 기록의 연결 대회로 넣는다 — 저장하면 서버가 대회명·연도를 그 대회 값으로 맞춘다.
public struct OpenCompetitionRecordPayload: Equatable, Sendable {
    /// 대회 id(숫자 또는 숫자 문자열)로 읽지 못하면 nil — 이름·연도만 채운 직접 입력으로 연다.
    public let competitionId: Int?
    public let name: String
    public let year: Int

    public init(competitionId: Int?, name: String, year: Int) {
        self.competitionId = competitionId
        self.name = name
        self.year = year
    }

    /// 웹이 보낸 값을 검사해 만든다. 이름·연도가 없으면 채울 값이 없어 빈 추가 화면만 뜨므로 nil.
    /// 연도는 정수·상식 범위만 받는다 — 터무니없는 값이면 연도 휠이 그 해까지 늘어난다.
    /// 대회 id를 읽지 못하면 연결 없이 연다 — id 때문에 기록 화면이 안 열리지 않게.
    init?(payload: [String: Any]?) {
        let name = (payload?["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let currentYear = Calendar.current.component(.year, from: Date())
        guard
            !name.isEmpty,
            let yearNumber = payload?["year"] as? NSNumber,
            CFGetTypeID(yearNumber) != CFBooleanGetTypeID(),
            yearNumber.doubleValue == yearNumber.doubleValue.rounded(),
            case let year = yearNumber.intValue,
            (1990...(currentYear + 1)).contains(year)
        else {
            return nil
        }
        self.init(competitionId: Self.parseCompetitionId(payload?["competitionId"]), name: name, year: year)
    }

    /// 웹 브리지가 보낸 대회 id(`OPEN_COMPETITION_RECORD`·`COMPETITION_ALERTS_ENABLED` 공용, #281).
    /// 숫자(Bool 제외)와 숫자 문자열("3")을 모두 받고, 양의 정수가 아니면 nil.
    static func parseCompetitionId(_ value: Any?) -> Int? {
        let id: Int? = switch value {
        case let number as NSNumber where CFGetTypeID(number) != CFBooleanGetTypeID():
            Int(exactly: number.doubleValue)
        case let text as String where DeepLinkParser.isCompetitionId(text):
            Int(text)
        default:
            nil
        }
        guard let id, id > 0 else { return nil }
        return id
    }
}
