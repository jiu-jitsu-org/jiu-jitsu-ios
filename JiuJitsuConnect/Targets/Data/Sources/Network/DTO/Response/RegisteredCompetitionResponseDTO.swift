//
//  RegisteredCompetitionResponseDTO.swift
//  Data
//

import Foundation
import Domain

/// 등록된 대회 검색 결과 항목(`GET /api/community/competitions?keyword=`).
struct RegisteredCompetitionResponseDTO: Decodable, Sendable {
    let competitionId: Int
    let name: String
    // 날짜를 모르는 대회는 null.
    let year: Int?

    func toDomain() -> RegisteredCompetition {
        RegisteredCompetition(id: competitionId, name: name, year: year)
    }
}
