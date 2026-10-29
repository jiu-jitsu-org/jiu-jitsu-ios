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
    // 출전 부문(#122) — backend #164 계약 전 가정 키. nil이면 키를 아예 보내지 않는다(합성 Encodable의 encodeIfPresent).
    let competitionUniform: String?
    let competitionWeightClass: String?
    let competitionBelt: String?
    // 맨 위 고정(#124) — 서버 계약 전 가정 키. 고정한 항목만 true를 보내고, 아니면 키를 보내지 않는다.
    // 목록 전체를 매번 다시 보내므로 키가 없으면 '고정 안 함'으로 읽힌다고 가정한다.
    let competitionPinned: Bool?
    // 회원이 끌어서 정한 자리(고정한 줄끼리, 고정 안 한 줄끼리 각각 0이 맨 위) — 서버 계약 전 가정 키. 정한 적 없으면 보내지 않는다.
    let competitionDisplayOrder: Int?

    init(from competition: Competition) {
        self.competitionYear = competition.competitionYear
        // backend #164 반영 전 임시: 서버가 아직 월을 필수로 받으므로, 월이 없는 새 기록은 자리값 1을 보낸다.
        // 기존 기록은 원래 월을 그대로 보내 서버 값이 바뀌지 않게 한다.
        self.competitionMonth = competition.competitionMonth ?? Self.placeholderMonth
        self.competitionName = competition.competitionName
        self.competitionRank = competition.competitionRank.rawValue
        self.competitionUniform = competition.competitionUniform?.rawValue
        self.competitionWeightClass = competition.competitionWeightClass?.rawValue
        self.competitionBelt = competition.competitionBelt?.rawValue
        self.competitionPinned = competition.isPinned ? true : nil
        self.competitionDisplayOrder = competition.displayOrder
    }
}
