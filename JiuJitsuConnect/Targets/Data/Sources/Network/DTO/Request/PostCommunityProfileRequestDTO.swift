//
//  PostCommunityProfileRequestDTO.swift
//  Data
//
//  Created by suni on 1/5/26.
//

import Foundation
import Domain

/// 커뮤니티 프로필 업데이트 요청 DTO
struct PostCommunityProfileRequestDTO: Codable {
    let nickname: String?
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
    let teachingPhilosophy: String?
    let teachingStartDate: String?
    let teachingDetail: String?
    
    init(from profile: CommunityProfile) {
        self.nickname = profile.nickname
        self.profileImageUrl = profile.profileImageUrl
        self.beltRank = profile.beltRank?.rawValue
        self.beltStripe = profile.beltStripe?.rawValue
        self.gender = profile.gender?.rawValue
        self.weightKg = profile.weightKg
        self.academyName = profile.academyName
        self.competitions = profile.competitions.isEmpty ? nil : profile.competitions.map { competition in
            CompetitionDTO(
                competitionYear: competition.competitionYear,
                competitionMonth: competition.competitionMonth,
                competitionName: competition.competitionName,
                competitionRank: competition.competitionRank.rawValue
            )
        }
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
