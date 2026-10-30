//
//  PostCommunityProfileRequestDTO.swift
//  Data
//
//  Created by suni on 1/5/26.
//

import Foundation
import Domain

/// 커뮤니티 프로필 업데이트 요청 DTO.
///
/// 프로필 이미지(`profileImageUrl`)는 user-level 데이터로 분리되어
/// `PUT /api/user/profile`에서 처리한다 — 본 DTO에는 포함하지 않는다.
struct PostCommunityProfileRequestDTO: Codable {
    let profileRequestType: String
    let beltRank: String?
    let beltStripe: String?
    let gender: String?
    let weightKg: Double?
    let academyName: String?
    let competitions: [CompetitionRequestDTO]?
    let bestSubmission: String?
    let favoriteSubmission: String?
    let bestTechnique: String?
    let favoriteTechnique: String?
    let bestPosition: String?
    let favoritePosition: String?
    let isWeightHidden: Bool?
    let teachingPhilosophy: String?
    let teachingStartDate: String?
    let teachingDetail: String?

    /// Domain 모델로부터 DTO 생성
    /// - Parameters:
    ///   - profile: 변환할 CommunityProfile
    ///   - section: 업데이트할 프로필 섹션 (기본값: academy)
    init(from profile: CommunityProfile, section: ProfileSection = .academy) {
        // Domain의 비즈니스 개념 → API의 기술적 파라미터로 변환
        self.profileRequestType = section.rawValue
        self.beltRank = profile.beltRank?.rawValue
        self.beltStripe = profile.beltStripe?.rawValue
        self.gender = profile.gender?.rawValue
        self.weightKg = profile.weightKg
        self.academyName = profile.academyName
        // 대회 저장은 목록 전체 교체라, 마지막 대회를 지울 때도 빈 배열을 보내야 한다(nil이면 400 R0001).
        // 다른 섹션 저장에서는 키를 보내지 않는다.
        self.competitions = section == .competition ? CompetitionRequestDTO.grouping(profile.competitions) : nil
        self.bestSubmission = profile.bestSubmission?.rawValue
        self.favoriteSubmission = profile.favoriteSubmission?.rawValue
        self.bestTechnique = profile.bestTechnique?.rawValue
        self.favoriteTechnique = profile.favoriteTechnique?.rawValue
        self.bestPosition = profile.bestPosition?.rawValue
        self.favoritePosition = profile.favoritePosition?.rawValue
        self.isWeightHidden = profile.isWeightHidden
        self.teachingPhilosophy = profile.teachingPhilosophy
        self.teachingStartDate = profile.teachingStartDate
        self.teachingDetail = profile.teachingDetail
    }
}

// MARK: - CompetitionRequestDTO

/// 대회 요청 DTO — 대회 한 건 아래에 출전 부문들을 묶는다.
struct CompetitionRequestDTO: Codable {
    let competitionYear: Int
    let competitionName: String
    let competitionPinned: Bool
    // 자동완성에서 고른 등록 대회. 직접 입력이면 키를 보내지 않는다.
    let competitionId: Int?
    let divisions: [CompetitionDivisionRequestDTO]

    /// 앱의 `Competition`(한 건 = 한 부문)을 같은 대회끼리 묶는다.
    /// 같은 대회 = 연도 + 앞뒤 공백 뺀 대회명. 이름 있는 같은 대회가 두 항목으로 가면 400(R0008)이라 반드시 합친다.
    /// 대회명 없는 기록은 같은 연도라도 각각 따로 보낸다. 대회 순서는 처음 나온 자리를 따른다.
    static func grouping(_ competitions: [Competition]) -> [CompetitionRequestDTO] {
        var groups: [[Competition]] = []
        var groupIndexByKey: [String: Int] = [:]
        for competition in competitions {
            let name = competition.competitionName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else {
                groups.append([competition])
                continue
            }
            let key = "\(competition.competitionYear)|\(name)"
            if let index = groupIndexByKey[key] {
                groups[index].append(competition)
            } else {
                groupIndexByKey[key] = groups.count
                groups.append([competition])
            }
        }
        return groups.map(CompetitionRequestDTO.init(divisionsOf:))
    }

    private init(divisionsOf competitions: [Competition]) {
        let first = competitions[0]
        self.competitionYear = first.competitionYear
        self.competitionName = first.competitionName.trimmingCharacters(in: .whitespaces)
        // 고정은 대회 단위 — 부문 중 하나라도 고정이면 대회를 고정한다.
        self.competitionPinned = competitions.contains(where: \.isPinned)
        self.competitionId = competitions.lazy.compactMap(\.competitionId).first
        self.divisions = competitions.map(CompetitionDivisionRequestDTO.init(from:))
    }
}

/// 출전 부문 요청 DTO. 비어 있는 값은 키를 보내지 않는다(합성 Encodable의 encodeIfPresent).
struct CompetitionDivisionRequestDTO: Codable {
    let competitionRank: String
    let competitionUniform: String?
    let competitionBelt: String?
    let competitionWeightLimit: Double?
    let competitionWeightBound: String?
    // 수정에서 앱솔루트를 끈 것도 서버에 닿도록 false까지 보낸다.
    let competitionAbsolute: Bool

    init(from competition: Competition) {
        self.competitionRank = competition.competitionRank.rawValue
        self.competitionUniform = competition.competitionUniform?.rawValue
        self.competitionBelt = competition.competitionBelt?.rawValue
        self.competitionWeightLimit = competition.competitionWeightLimit?.kg
        self.competitionWeightBound = competition.competitionWeightLimit?.bound.rawValue
        self.competitionAbsolute = competition.competitionAbsolute
    }
}
