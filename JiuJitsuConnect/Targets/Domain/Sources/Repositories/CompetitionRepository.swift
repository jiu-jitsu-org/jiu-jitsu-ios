//
//  CompetitionRepository.swift
//  Domain
//

import Foundation

/// 등록된 대회 데이터 작업을 위한 Repository 프로토콜
public protocol CompetitionRepository: Sendable {
    /// 대회명 일부로 등록된 대회를 검색합니다 (자동완성용)
    /// - Parameter keyword: 사용자가 입력한 대회명 일부
    /// - Returns: 검색어와 맞는 등록된 대회 목록
    /// - Throws: DomainError
    func searchCompetitions(keyword: String) async throws -> [RegisteredCompetition]
}
