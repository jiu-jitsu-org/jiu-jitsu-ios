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
            profileImageUrl: profileImageUrl,
            beltRank: beltRank.flatMap { BeltRank(rawValue: $0) },
            beltStripe: beltStripe.flatMap { BeltStripe(rawValue: $0) },
            gender: gender.flatMap { Gender(rawValue: $0) },
            weightKg: weightKg,
            academyName: academyName,
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
    let competitionMonth: Int
    let competitionName: String
    let competitionRank: String
    
    func toDomain() -> Competition {
        Competition(
            competitionYear: competitionYear,
            competitionMonth: competitionMonth,
            competitionName: competitionName,
            competitionRank: CompetitionRank(rawValue: competitionRank) ?? .participation
        )
    }
}
