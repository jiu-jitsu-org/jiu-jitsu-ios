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
    private static let placeholderMonth = 1

    let competitionYear: Int
    let competitionMonth: Int
    let competitionName: String
    let competitionRank: String
    
    init(from competition: Competition) {
        self.competitionYear = competition.competitionYear
        // backend #164 반영 전 임시: 서버가 아직 월을 필수로 받으므로, 월이 없는 새 기록은 자리값 1을 보낸다.
        // 기존 기록은 원래 월을 그대로 보내 서버 값이 바뀌지 않게 한다.
        self.competitionMonth = competition.competitionMonth ?? Self.placeholderMonth
        self.competitionName = competition.competitionName
        self.competitionRank = competition.competitionRank.rawValue
    }
}
