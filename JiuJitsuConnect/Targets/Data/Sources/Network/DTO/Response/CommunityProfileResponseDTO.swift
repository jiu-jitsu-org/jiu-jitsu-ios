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
            competitions: competitions?.map { $0.toDomain() } ?? [],
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

/// 대회 정보 DTO
struct CompetitionDTO: Codable {
    let competitionYear: Int
    // 연도만 받는 서버(backend #164)로 바뀌면 월이 빠질 수 있어 옵셔널로 디코딩한다.
    let competitionMonth: Int?
    let competitionName: String
    let competitionRank: String
    // 출전 부문(#122) — backend #164 계약 전 가정 키. 서버가 아직 내려 주지 않으므로 옵셔널로 디코딩한다.
    let competitionUniform: String?
    let competitionWeightClass: String?
    let competitionBelt: String?
    // 맨 위 고정(#124) — 서버 계약 전 가정 키. 내려오지 않으면 고정 안 함.
    let competitionPinned: Bool?

    func toDomain() -> Competition {
        // 모르는 값은 부문 없음으로 둔다 — 체급표가 바뀌어도 프로필 전체 디코딩이 깨지지 않게.
        Competition(
            competitionYear: competitionYear,
            competitionMonth: competitionMonth,
            competitionName: competitionName,
            competitionRank: CompetitionRank(rawValue: competitionRank) ?? .participation,
            competitionUniform: competitionUniform.flatMap(CompetitionUniform.init(rawValue:)),
            competitionWeightClass: competitionWeightClass.flatMap(CompetitionWeightClass.init(rawValue:)),
            competitionBelt: competitionBelt.flatMap(BeltRank.init(rawValue:)),
            isPinned: competitionPinned ?? false
        )
    }
}
