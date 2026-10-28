//
//  CompetitionClient.swift
//  Presentation
//
//  등록된 대회 검색(대회명 자동완성) TCA Dependency.
//

import ComposableArchitecture
import Domain

public struct CompetitionClient: Sendable {
    /// 대회명 일부로 등록된 대회 검색 (GET `/api/competition?keyword=`)
    public var searchCompetitions: @Sendable (String) async throws -> [RegisteredCompetition]

    public init(
        searchCompetitions: @Sendable @escaping (String) async throws -> [RegisteredCompetition]
    ) {
        self.searchCompetitions = searchCompetitions
    }
}

extension CompetitionClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = .unimplemented

    /// 프리뷰·스냅샷용 — 디자인 제안의 예시 대회들에서 검색어를 포함하는 항목을 돌려준다.
    public static let previewValue: Self = Self(
        searchCompetitions: { keyword in
            mockCompetitions.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
        }
    )

    static let mockCompetitions: [RegisteredCompetition] = [
        RegisteredCompetition(id: 1, name: "2026 서울 오픈"),
        RegisteredCompetition(id: 2, name: "서울 주짓수 챔피언십"),
        RegisteredCompetition(id: 3, name: "서울 국제 오픈"),
        RegisteredCompetition(id: 4, name: "2025 전국 주짓수 선수권"),
        RegisteredCompetition(id: 5, name: "2024 부산 오픈"),
        RegisteredCompetition(id: 6, name: "강남 주짓수 토너먼트")
    ]
}

public extension DependencyValues {
    var competitionClient: CompetitionClient {
        get { self[CompetitionClient.self] }
        set { self[CompetitionClient.self] = newValue }
    }
}

extension CompetitionClient {
    static let unimplemented: Self = Self(
        searchCompetitions: { _ in fatalError("competitionClient.searchCompetitions is not implemented") }
    )
}
