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
    // 공개 일정의 대회 날짜(#126) — 가정 키, "yyyy-MM-dd"(또는 "yyyy-MM-dd'T'…")로 시작한다고 가정한다.
    // 앱은 연도만 쓰므로 앞 4자리만 읽고, 없거나 형식이 다르면 날짜 모르는 대회로 둔다.
    let competitionDate: String?

    func toDomain() -> RegisteredCompetition {
        RegisteredCompetition(
            id: competitionId,
            name: competitionName,
            year: competitionDate.flatMap { Int($0.prefix(4)) }
        )
    }
}
