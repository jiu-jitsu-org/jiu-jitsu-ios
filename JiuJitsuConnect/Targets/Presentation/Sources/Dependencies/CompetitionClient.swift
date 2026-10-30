//
//  CompetitionClient.swift
//  Presentation
//
//  등록된 대회 검색(대회명 자동완성) TCA Dependency.
//

import ComposableArchitecture
import Domain

public struct CompetitionClient: Sendable {
    /// 대회명 일부로 등록된 대회 검색 (GET `/api/community/competitions?keyword=`)
    public var searchCompetitions: @Sendable (String) async throws -> [RegisteredCompetition]

    public init(
        searchCompetitions: @Sendable @escaping (String) async throws -> [RegisteredCompetition]
    ) {
        self.searchCompetitions = searchCompetitions
    }
}

extension CompetitionClient: DependencyKey {
    /// 실제 구현은 App의 DependencyContainer에서 주입한다.
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = .unimplemented

    /// 프리뷰·스냅샷용 — 디자인 제안의 예시 대회들에서 검색어를 포함하는 항목을 돌려준다.
    public static let previewValue: Self = Self(
        searchCompetitions: { keyword in
            mockCompetitions.filter { $0.name.competitionSearchKey.contains(keyword.competitionSearchKey) }
        }
    )

    // 연도가 있는 항목은 공개 일정에서 온 대회(#126), 없는 항목은 날짜를 모르는 대회.
    static let mockCompetitions: [RegisteredCompetition] = [
        RegisteredCompetition(id: 1, name: "2026 서울 오픈", year: 2026),
        RegisteredCompetition(id: 2, name: "서울 주짓수 챔피언십"),
        RegisteredCompetition(id: 3, name: "서울 국제 오픈", year: 2025),
        RegisteredCompetition(id: 4, name: "2025 전국 주짓수 선수권", year: 2025),
        RegisteredCompetition(id: 5, name: "2024 부산 오픈", year: 2024),
        RegisteredCompetition(id: 6, name: "강남 주짓수 토너먼트")
    ]
}

public extension DependencyValues {
    var competitionClient: CompetitionClient {
        get { self[CompetitionClient.self] }
        set { self[CompetitionClient.self] = newValue }
    }
}

// MARK: - Search Key

extension String {
    /// 대회명 비교용 — 띄어쓰기와 대소문자를 무시해 '서울오픈'으로 쳐도 '서울 오픈'과 맞게 한다.
    var competitionSearchKey: String {
        lowercased().filter { !$0.isWhitespace }
    }
}

extension CompetitionClient {
    static let unimplemented: Self = Self(
        searchCompetitions: { _ in fatalError("competitionClient.searchCompetitions is not implemented") }
    )
}
