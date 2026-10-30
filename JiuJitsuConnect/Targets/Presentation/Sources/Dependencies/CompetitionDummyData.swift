//
//  CompetitionDummyData.swift
//  Presentation
//
//  ⚠️ 임시 더미 데이터 (Debug·Beta 전용)
//  backend #164(부문·고정)·#165(대회 검색)가 개발 서버에 배포되기 전, develop 빌드에서 대회 기록 개편 화면을
//  끝까지 확인하려고 넣은 가짜 데이터다. API 연결 PR에서 이 파일과 사용처를 함께 지운다.
//  - 사용처 1: CompetitionClient.liveValue (#121·#126)
//  - 사용처 2: JiuJitsuConnectApp의 `withCompetitionDummyFields()` (#122·#123·#124)
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

// MARK: - #122·#123·#124 출전 부문·고정

extension CommunityClient {
    /// 서버(backend #164)가 아직 부문·고정을 저장하지 않아, 앱이 저장한 값을 기기에 남겨 두고 서버 응답에 다시 얹는다.
    /// 대회명·연도·메달이 같은 기록끼리 짝지으며, 앱을 다시 켜도 남는다(UserDefaults).
    public func withCompetitionDummyFields() -> CommunityClient {
        let base = self
        return CommunityClient(
            fetchProfile: {
                CompetitionDummyStore.applying(to: try await base.fetchProfile())
            },
            updateProfile: { profile, section in
                if section == .competition {
                    CompetitionDummyStore.save(profile.competitions)
                }
                return CompetitionDummyStore.applying(to: try await base.updateProfile(profile, section))
            }
        )
    }
}

private enum CompetitionDummyStore {
    private static let key = "debug.competitionDummyFields"

    static func save(_ competitions: [Competition]) {
        guard let data = try? JSONEncoder().encode(competitions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func applying(to profile: CommunityProfile) -> CommunityProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([Competition].self, from: data) else { return profile }

        var used = Set<Int>()
        let merged = profile.competitions.map { server -> Competition in
            guard let index = stored.indices.first(where: {
                !used.contains($0) && isSameRecord(stored[$0], server)
            }) else { return server }
            used.insert(index)
            let local = stored[index]
            return Competition(
                competitionYear: server.competitionYear,
                competitionMonth: server.competitionMonth,
                competitionName: server.competitionName,
                competitionRank: server.competitionRank,
                competitionUniform: local.competitionUniform,
                competitionWeightLimit: local.competitionWeightLimit,
                competitionAbsolute: local.competitionAbsolute,
                competitionBelt: local.competitionBelt,
                isPinned: local.isPinned
            )
        }
        // replacingCompetitions가 private이라 공개 메서드로 목록을 갈아 끼운다.
        let cleared = profile.competitions.reduce(profile) { $0.removingCompetition($1) }
        return merged.reduce(cleared) { $0.addingCompetition($1) }
    }

    private static func isSameRecord(_ lhs: Competition, _ rhs: Competition) -> Bool {
        lhs.competitionName == rhs.competitionName
            && lhs.competitionYear == rhs.competitionYear
            && lhs.competitionRank == rhs.competitionRank
    }
}
#endif
