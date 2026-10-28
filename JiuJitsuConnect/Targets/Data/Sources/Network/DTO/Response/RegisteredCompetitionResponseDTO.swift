//
//  RegisteredCompetitionResponseDTO.swift
//  Data
//

import Foundation
import Domain

/// 등록된 대회 검색 결과 항목(`GET /api/competition?keyword=`).
/// backend #165 미구현 — `data`가 항목 배열이라고 가정한다(`/api/notice` 목록과 같은 형태).
/// 자동완성에 필요한 이름만 필수로 두고, 나머지는 서버 계약이 바뀌어도 디코딩이 깨지지 않게 옵셔널로 둔다.
struct RegisteredCompetitionResponseDTO: Decodable, Sendable {
    let competitionId: Int?
    let competitionName: String

    func toDomain() -> RegisteredCompetition {
        RegisteredCompetition(id: competitionId, name: competitionName)
    }
}
