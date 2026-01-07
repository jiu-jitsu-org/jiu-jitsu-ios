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
    let profileRequestType: String
    let beltRank: String?
    let beltStripe: String?
    let gender: String?
    let weightKg: Double?
    let academyName: String?
    let competitionInfoList: [CompetitionRequestDTO]?
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
        self.competitionInfoList = profile.competitions.isEmpty ? nil : profile.competitions.map { 
            CompetitionRequestDTO(from: $0) 
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

// MARK: - CompetitionRequestDTO

/// 대회 정보 요청 DTO
struct CompetitionRequestDTO: Codable {
    let competitionYear: Int
    let competitionMonth: Int
    let competitionName: String
    let competitionRank: String
    
    init(from competition: Competition) {
        self.competitionYear = competition.competitionYear
        self.competitionMonth = competition.competitionMonth
        self.competitionName = competition.competitionName
        self.competitionRank = competition.competitionRank.rawValue
    }
}
