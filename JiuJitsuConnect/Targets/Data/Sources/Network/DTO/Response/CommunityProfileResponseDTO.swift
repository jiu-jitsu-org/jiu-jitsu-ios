//
//  CommunityProfileResponseDTO.swift
//  Data
//
//  Created by suni on 1/5/26.
//

import Foundation
import Domain

/// 커뮤니티 프로필 API 응답 DTO
struct CommunityProfileResponseDTO: Codable {
    let nickname: String
    let profileImageUrl: String?
    let beltRank: String?
    let beltStripe: String?
    let gender: String?
    let weightKg: Double?
    let academyName: String?
    let competitions: [CompetitionDTO]?
    let bestSubmission: String?
    let favoriteSubmission: String?
    let bestTechnique: String?
    let favoriteTechnique: String?
    let bestPosition: String?
    let favoritePosition: String?
    let isWeightHidden: Bool?
    let isOwner: Bool?
    let teachingPhilosophy: String?
    let teachingStartDate: String?
    let teachingDetail: String?
    
    /// DTO를 Domain 모델로 변환
    func toDomain() -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            // BE sentinel "default" → nil 정규화 (도메인은 sentinel을 알지 못함)
            profileImageUrl: ProfileImageSentinel.normalize(profileImageUrl),
            beltRank: beltRank.flatMap { BeltRank(rawValue: $0) },
            beltStripe: beltStripe.flatMap { BeltStripe(rawValue: $0) },
            gender: gender.flatMap { Gender(rawValue: $0) },
            weightKg: weightKg,
            // 도장 삭제 시 BE가 "" 로 회신 → nil 정규화 (UI는 nil 여부로 "입력하기" 버튼 분기)
            academyName: academyName.flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 },
            // 서버는 대회 → 부문 중첩으로 내려 준다. 앱은 한 건 = 한 부문이라 부문마다 펼친다(순서는 서버 정렬 그대로).
            competitions: competitions?.flatMap { $0.toDomain() } ?? [],
            bestSubmission: bestSubmission.flatMap { SubmissionType(rawValue: $0) },
            favoriteSubmission: favoriteSubmission.flatMap { SubmissionType(rawValue: $0) },
            bestTechnique: bestTechnique.flatMap { TechniqueType(rawValue: $0) },
            favoriteTechnique: favoriteTechnique.flatMap { TechniqueType(rawValue: $0) },
            bestPosition: bestPosition.flatMap { PositionType(rawValue: $0) },
            favoritePosition: favoritePosition.flatMap { PositionType(rawValue: $0) },
            isWeightHidden: isWeightHidden ?? false,
            isOwner: isOwner ?? false,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
}

/// 대회 정보 DTO — 대회 한 건 아래에 출전 부문들이 있다.
struct CompetitionDTO: Codable {
    let competitionYear: Int
    // 대회명 없는 기록은 ""로 온다.
    let competitionName: String
    let competitionPinned: Bool?
    // 등록 대회에서 고른 기록이면 ID, 직접 입력이면 null.
    let competitionId: Int?
    let divisions: [CompetitionDivisionDTO]?

    func toDomain() -> [Competition] {
        (divisions ?? []).map { division in
            division.toDomain(
                year: competitionYear,
                name: competitionName,
                isPinned: competitionPinned ?? false,
                competitionId: competitionId
            )
        }
    }
}

/// 출전 부문 DTO
struct CompetitionDivisionDTO: Codable {
    let competitionRank: String
    let competitionUniform: String?
    let competitionBelt: String?
    let competitionWeightLimit: Double?
    let competitionWeightBound: String?
    let competitionAbsolute: Bool?

    /// 무게와 이하/초과가 모두 있어야 체급으로 본다.
    private var weightLimit: CompetitionWeightLimit? {
        guard let competitionWeightLimit,
              let bound = competitionWeightBound.flatMap(CompetitionWeightLimit.Bound.init(rawValue:)) else {
            return nil
        }
        return CompetitionWeightLimit(kg: competitionWeightLimit, bound: bound)
    }

    func toDomain(year: Int, name: String, isPinned: Bool, competitionId: Int?) -> Competition {
        // 모르는 값은 부문 없음으로 둔다 — 값이 늘어나도 프로필 전체 디코딩이 깨지지 않게.
        Competition(
            competitionYear: year,
            competitionName: name,
            competitionRank: CompetitionRank(rawValue: competitionRank) ?? .participation,
            competitionUniform: competitionUniform.flatMap(CompetitionUniform.init(rawValue:)),
            competitionWeightLimit: weightLimit,
            competitionAbsolute: competitionAbsolute ?? false,
            competitionBelt: competitionBelt.flatMap(BeltRank.init(rawValue:)),
            isPinned: isPinned,
            competitionId: competitionId
        )
    }
}
