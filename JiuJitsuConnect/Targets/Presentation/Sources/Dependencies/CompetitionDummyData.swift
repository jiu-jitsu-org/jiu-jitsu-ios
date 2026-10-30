//
//  CompetitionDummyData.swift
//  Presentation
//
//  ⚠️ 임시 더미 데이터 (Debug·Beta 전용)
//  대회 검색(#121·#126)을 서버에 연결하기 전, develop 빌드에서 대회명 자동완성을 확인하려고 넣은 가짜 데이터다.
//  검색 API 연결 PR에서 이 파일과 사용처를 함께 지운다.
//  - 사용처: CompetitionClient.liveValue (#121·#126)
//

#if DEBUG || BETA
import Foundation
import ComposableArchitecture
import Domain

// MARK: - #121·#126 대회 검색

extension CompetitionClient {
    /// 검색 API(backend #165) 대신 기기 안의 가짜 대회 목록에서 찾는다.
    static let dummyValue: Self = Self(
        searchCompetitions: { keyword in
            try await Task.sleep(for: .milliseconds(200))
            return dummyCompetitions.filter { $0.name.competitionSearchKey.contains(keyword.competitionSearchKey) }
        }
    )

    // 연도가 있는 항목은 공개 일정 대회(#126 연도 미리 골라 두기), 없는 항목은 날짜를 모르는 대회.
    // '서울'·'오픈'은 20개가 넘게 걸리게 해 목록 20개 제한·끝 흐림을 볼 수 있게 했다.
    private static let dummyCompetitions: [RegisteredCompetition] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        var list: [RegisteredCompetition] = [
            RegisteredCompetition(id: 1, name: "\(currentYear) 서울 오픈", year: currentYear),
            RegisteredCompetition(id: 2, name: "\(currentYear + 1) 서울 오픈", year: currentYear + 1),
            RegisteredCompetition(id: 3, name: "서울 주짓수 챔피언십"),
            RegisteredCompetition(id: 4, name: "서울 국제 오픈", year: currentYear - 1),
            RegisteredCompetition(id: 5, name: "\(currentYear - 1) 전국 주짓수 선수권", year: currentYear - 1),
            RegisteredCompetition(id: 6, name: "\(currentYear - 2) 부산 오픈", year: currentYear - 2),
            RegisteredCompetition(id: 7, name: "강남 주짓수 토너먼트"),
            RegisteredCompetition(id: 8, name: "서울 오픈"),
            RegisteredCompetition(id: 9, name: "서울 오픈"),
            RegisteredCompetition(id: 10, name: "아주 긴 이름의 서울 오픈 주짓수 챔피언십 마스터 노기 부문 대회")
        ]
        for index in 1...15 {
            list.append(RegisteredCompetition(id: 100 + index, name: "서울 더미 오픈 \(index)", year: currentYear - index))
        }
        return list
    }()
}

#endif
