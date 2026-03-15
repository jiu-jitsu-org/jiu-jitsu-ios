//
//  CommunityProfile.swift
//  Domain
//
//  Created by suni on 1/5/26.
//

import Foundation

/// 커뮤니티 프로필 정보를 나타내는 도메인 모델
public struct CommunityProfile: Codable, Equatable, Sendable {
    /// 사용자 닉네임
    public let nickname: String
    
    /// 프로필 이미지 URL
    public let profileImageUrl: String?
    
    /// 벨트 등급
    public let beltRank: BeltRank?
    
    /// 벨트 띠 개수
    public let beltStripe: BeltStripe?
    
    /// 성별
    public let gender: Gender?
    
    /// 체중 (kg)
    public let weightKg: Double?
    
    /// 도장명
    public let academyName: String?
    
    /// 대회 참가 이력
    public let competitions: [Competition]
    
    /// 최고 서브미션
    public let bestSubmission: SubmissionType?
    
    /// 선호 서브미션
    public let favoriteSubmission: SubmissionType?
    
    /// 최고 기술
    public let bestTechnique: TechniqueType?
    
    /// 선호 기술
    public let favoriteTechnique: TechniqueType?
    
    /// 최고 포지션
    public let bestPosition: PositionType?
    
    /// 선호 포지션
    public let favoritePosition: PositionType?
    
    /// 체중 숨김 여부
    public let isWeightHidden: Bool
    
    /// 프로필 소유자 여부 (본인 프로필인지)
    public let isOwner: Bool
    
    /// 지도 철학 (코치/관장용)
    public let teachingPhilosophy: String?
    
    /// 지도 시작일 (코치/관장용)
    public let teachingStartDate: String?
    
    /// 지도 상세 정보 (코치/관장용)
    public let teachingDetail: String?
    
    public init(
        nickname: String,
        profileImageUrl: String? = nil,
        beltRank: BeltRank? = nil,
        beltStripe: BeltStripe? = nil,
        gender: Gender? = nil,
        weightKg: Double? = nil,
        academyName: String? = nil,
        competitions: [Competition] = [],
        bestSubmission: SubmissionType? = nil,
        favoriteSubmission: SubmissionType? = nil,
        bestTechnique: TechniqueType? = nil,
        favoriteTechnique: TechniqueType? = nil,
        bestPosition: PositionType? = nil,
        favoritePosition: PositionType? = nil,
        isWeightHidden: Bool = false,
        isOwner: Bool = false,
        teachingPhilosophy: String? = nil,
        teachingStartDate: String? = nil,
        teachingDetail: String? = nil
    ) {
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.beltRank = beltRank
        self.beltStripe = beltStripe
        self.gender = gender
        self.weightKg = weightKg
        self.academyName = academyName
        self.competitions = competitions
        self.bestSubmission = bestSubmission
        self.favoriteSubmission = favoriteSubmission
        self.bestTechnique = bestTechnique
        self.favoriteTechnique = favoriteTechnique
        self.bestPosition = bestPosition
        self.favoritePosition = favoritePosition
        self.isWeightHidden = isWeightHidden
        self.isOwner = isOwner
        self.teachingPhilosophy = teachingPhilosophy
        self.teachingStartDate = teachingStartDate
        self.teachingDetail = teachingDetail
    }
}

// MARK: - Convenience Update Methods

extension CommunityProfile {
    /// 도장명 업데이트
    public func updatingAcademy(_ academyName: String?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 벨트 정보 업데이트
    public func updatingBelt(rank: BeltRank, stripe: BeltStripe) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: rank,
            beltStripe: stripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 체급 정보 업데이트
    public func updatingWeight(gender: Gender, weightKg: Double, isWeightHidden: Bool) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 벨트와 체급 정보 함께 업데이트
    public func updatingBeltAndWeight(
        rank: BeltRank,
        stripe: BeltStripe,
        gender: Gender,
        weightKg: Double,
        isWeightHidden: Bool
    ) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: rank,
            beltStripe: stripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 체급 가시성 토글
    public func togglingWeightVisibility() -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: !isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 포지션 정보 업데이트 (특기만)
    public func updatingPositionBest(_ best: PositionType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: best,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 포지션 정보 업데이트 (특기 + 최애)
    public func updatingPositionFavorite(best: PositionType?, favorite: PositionType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: best,
            favoritePosition: favorite,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 서브미션 정보 업데이트 (특기만)
    public func updatingSubmissionBest(_ best: SubmissionType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: best,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 서브미션 정보 업데이트 (특기 + 최애)
    public func updatingSubmissionFavorite(best: SubmissionType?, favorite: SubmissionType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: best,
            favoriteSubmission: favorite,
            bestTechnique: bestTechnique,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 기술 정보 업데이트 (특기만)
    public func updatingTechniqueBest(_ best: TechniqueType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: best,
            favoriteTechnique: favoriteTechnique,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
    
    /// 기술 정보 업데이트 (특기 + 최애)
    public func updatingTechniqueFavorite(best: TechniqueType?, favorite: TechniqueType?) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: competitions,
            bestSubmission: bestSubmission,
            favoriteSubmission: favoriteSubmission,
            bestTechnique: best,
            favoriteTechnique: favorite,
            bestPosition: bestPosition,
            favoritePosition: favoritePosition,
            isWeightHidden: isWeightHidden,
            isOwner: isOwner,
            teachingPhilosophy: teachingPhilosophy,
            teachingStartDate: teachingStartDate,
            teachingDetail: teachingDetail
        )
    }
}

// MARK: - Enums

/// 프로필 섹션 (수정/조회 단위)
///
/// 사용자 프로필의 논리적 구분 단위를 나타냅니다.
/// UI에서 섹션별 수정이 가능하며, 각 섹션은 독립적으로 업데이트됩니다.
public enum ProfileSection: String, Codable, Sendable, CaseIterable, Equatable {
    /// 도장 정보 (academyName)
    case academy = "ACADEMY"
    
    /// 벨트/체급 정보 (beltRank, beltStripe, gender, weightKg)
    case beltWeight = "BELT_WEIGHT"
    
    /// 포지션 특기 (bestPosition)
    case positionBest = "POSITION_BEST"
    
    /// 포지션 최애 (favoritePosition)
    case positionFavorite = "POSITION_FAVORITE"
    
    /// 서브미션 특기 (bestSubmission)
    case submissionBest = "SUBMISSION_BEST"
    
    /// 서브미션 최애 (favoriteSubmission)
    case submissionFavorite = "SUBMISSION_FAVORITE"
    
    /// 기술 특기 (bestTechnique)
    case techniqueBest = "TECHNIQUE_BEST"
    
    /// 기술 최애 (favoriteTechnique)
    case techniqueFavorite = "TECHNIQUE_FAVORITE"
    
    /// 대회 정보 (competitions)
    case competition = "COMPETITION"
    
    /// 지도자 정보 (teachingPhilosophy, teachingStartDate, teachingDetail)
    case instructorInfo = "OWNER_INFO"
    
    /// 섹션의 한글 이름
    public var displayName: String {
        switch self {
        case .academy:
            return "도장 정보"
        case .beltWeight:
            return "벨트/체급"
        case .positionBest:
            return "포지션 특기"
        case .positionFavorite:
            return "포지션 최애"
        case .submissionBest:
            return "서브미션 특기"
        case .submissionFavorite:
            return "서브미션 최애"
        case .techniqueBest:
            return "기술 특기"
        case .techniqueFavorite:
            return "기술 최애"
        case .competition:
            return "대회 기록"
        case .instructorInfo:
            return "지도자 정보"
        }
    }
}

/// 주짓수 벨트 등급
public enum BeltRank: String, Codable, Equatable, Sendable, CaseIterable, Identifiable, Hashable {
    case white = "WHITE"
    case blue = "BLUE"
    case purple = "PURPLE"
    case brown = "BROWN"
    case black = "BLACK"
    
    /// Identifiable 준수를 위한 id
    public var id: String { rawValue }
    
    /// 벨트의 한글 이름
    public var displayName: String {
        switch self {
        case .white: return "화이트"
        case .blue: return "블루"
        case .purple: return "퍼플"
        case .brown: return "브라운"
        case .black: return "블랙"
        }
    }
}

/// 벨트 띠 개수
public enum BeltStripe: String, Codable, Equatable, Sendable, CaseIterable, Identifiable, Hashable {
    case none = "STRIPE_0"
    case one = "STRIPE_1"
    case two = "STRIPE_2"
    case three = "STRIPE_3"
    case four = "STRIPE_4"
    
    /// Identifiable 준수를 위한 id
    public var id: String { rawValue }
    
    /// 띠 개수
    public var count: Int {
        switch self {
        case .none: return 0
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        }
    }
    
    /// 띠의 한글 표현
    public var displayName: String {
        switch self {
        case .none: return "무그랄"
        case .one: return "1그랄"
        case .two: return "2그랄"
        case .three: return "3그랄"
        case .four: return "4그랄"
        }
    }
}

/// 성별
public enum Gender: String, Codable, Equatable, Sendable {
    case male = "MALE"
    case female = "FEMALE"
    case other = "OTHER"
    
    public var displayName: String {
        switch self {
        case .male: return "남자"
        case .female: return "여자"
        case .other: return "기타"
        }
    }
}

/// 서브미션 타입
public enum SubmissionType: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case chokes = "CHOKES"
    case armLocks = "ARM_LOCKS"
    case legLocks = "LEG_LOCKS"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .armLocks:
            return "팔 관절기"
        case .chokes:
            return "조르기"
        case .legLocks:
            return "하체 관절기"
        }
    }
}

/// 기술 타입
public enum TechniqueType: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case guardPasses = "GUARD_PASSES"
    case sweeps = "SWEEPS"
    case takedowns = "TAKEDOWNS"
    case escapes = "ESCAPES"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .takedowns:
            return "테이크다운"
        case .sweeps:
            return "스윕 · 뒤집기"
        case .escapes:
            return "이스케이프\n디펜스"
        case .guardPasses:
            return "가드패스"
        }
    }
}

/// 포지션 타입
public enum PositionType: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case top = "TOP"
    case `guard` = "GUARD"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .top: return "탑 포지션"
        case .guard: return "가드 포지션"
        }
    }
}

/// 대회 참가 이력
public struct Competition: Codable, Equatable, Sendable {
    /// 대회 년도
    public let competitionYear: Int
    
    /// 대회 월
    public let competitionMonth: Int
    
    /// 대회 이름
    public let competitionName: String
    
    /// 대회 순위
    public let competitionRank: CompetitionRank
    
    public init(
        competitionYear: Int,
        competitionMonth: Int,
        competitionName: String,
        competitionRank: CompetitionRank
    ) {
        self.competitionYear = competitionYear
        self.competitionMonth = competitionMonth
        self.competitionName = competitionName
        self.competitionRank = competitionRank
    }
}

/// 대회 순위
public enum CompetitionRank: String, Codable, Equatable, Sendable {
    case gold = "GOLD"
    case silver = "SILVER"
    case bronze = "BRONZE"
    case participation = "PARTICIPATION"
    
    public var displayName: String {
        switch self {
        case .gold: return "금메달"
        case .silver: return "은메달"
        case .bronze: return "동메달"
        case .participation: return "참가"
        }
    }
    
    public var emoji: String {
        switch self {
        case .gold: return "🥇"
        case .silver: return "🥈"
        case .bronze: return "🥉"
        case .participation: return "🎖️"
        }
    }
}
