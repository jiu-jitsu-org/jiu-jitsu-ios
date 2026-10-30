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
    /// 대회 정보 추가 (서버 저장 전 로컬 반영용)
    public func addingCompetition(_ competition: Competition) -> CommunityProfile {
        replacingCompetitions(competitions + [competition])
    }

    /// 대회 정보 수정 — 원본과 값이 동일한 항목을 새 값으로 치환
    public func updatingCompetition(original: Competition, with updated: Competition) -> CommunityProfile {
        // Competition은 식별자가 없어 값 비교로 매칭한다. 중복 입력된 동일 값 항목이 있을 경우
        // 첫 번째 일치 항목만 치환되도록 firstIndex 기반으로 처리한다.
        var newCompetitions = competitions
        if let index = newCompetitions.firstIndex(of: original) {
            newCompetitions[index] = updated
        }
        return replacingCompetitions(newCompetitions)
    }

    /// 대회 정보 삭제 — 원본과 값이 동일한 첫 번째 항목 제거
    public func removingCompetition(_ competition: Competition) -> CommunityProfile {
        var newCompetitions = competitions
        if let index = newCompetitions.firstIndex(of: competition) {
            newCompetitions.remove(at: index)
        }
        return replacingCompetitions(newCompetitions)
    }

    /// 여러 항목(묶인 한 줄의 부문들)의 고정 여부를 한꺼번에 바꾼다.
    /// 값이 완전히 같은 항목이 여럿이어도 대상 개수만큼만 바꾸도록, 이미 바꾼 위치는 다시 고르지 않는다.
    public func settingCompetitionsPinned(_ targets: [Competition], isPinned: Bool) -> CommunityProfile {
        var newCompetitions = competitions
        var changedIndices = Set<Int>()
        for target in targets {
            guard let index = newCompetitions.indices.first(where: {
                !changedIndices.contains($0) && newCompetitions[$0] == target
            }) else { continue }
            newCompetitions[index] = target.settingPinned(isPinned)
            changedIndices.insert(index)
        }
        return replacingCompetitions(newCompetitions)
    }

    private func replacingCompetitions(_ newCompetitions: [Competition]) -> CommunityProfile {
        CommunityProfile(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            beltRank: beltRank,
            beltStripe: beltStripe,
            gender: gender,
            weightKg: weightKg,
            academyName: academyName,
            competitions: newCompetitions,
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

    /// 닉네임 업데이트
    public func updatingNickname(_ newNickname: String) -> CommunityProfile {
        CommunityProfile(
            nickname: newNickname,
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
    
    /// 포지션 정보 업데이트 (특기 + 최애)
    public func updatingPosition(best: PositionType?, favorite: PositionType?) -> CommunityProfile {
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

    /// 서브미션 정보 업데이트 (특기 + 최애)
    public func updatingSubmission(best: SubmissionType?, favorite: SubmissionType?) -> CommunityProfile {
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

    /// 기술 정보 업데이트 (특기 + 최애)
    public func updatingTechnique(best: TechniqueType?, favorite: TechniqueType?) -> CommunityProfile {
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
    
    /// 포지션 (bestPosition + favoritePosition)
    case position = "POSITION"

    /// 서브미션 (bestSubmission + favoriteSubmission)
    case submission = "SUBMISSION"

    /// 기술 (bestTechnique + favoriteTechnique)
    case technique = "TECHNIQUE"
    
    /// 대회 정보 (competitions)
    case competition = "COMPETITION"
    
    /// 지도자 정보 (teachingPhilosophy, teachingStartDate, teachingDetail)
    case instructorInfo = "OWNER_INFO"

    // NOTE: 프로필 이미지(`profileImageUrl`)는 커뮤니티 프로필 섹션이 아닌
    // user-level 데이터로 분리되어 `PUT /api/user/profile`로 갱신한다.

    /// 섹션의 한글 이름
    public var displayName: String {
        switch self {
        case .academy:
            return "도장 정보"
        case .beltWeight:
            return "벨트/체급"
        case .position:
            return "포지션"
        case .submission:
            return "서브미션"
        case .technique:
            return "기술"
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
    case takedowns = "TAKE_DOWNS"
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
    
    /// 대회 월 — 몇 월이었는지 기억하지 못해 입력이 막히지 않도록 연도만 받는다(#120).
    /// 연도만 받기 전에 저장된 기록에만 값이 있다. 새 기록은 nil.
    public let competitionMonth: Int?
    
    /// 대회 이름
    public let competitionName: String
    
    /// 대회 순위
    public let competitionRank: CompetitionRank

    // 출전 부문(#122) — 부문 단계는 건너뛸 수 있고, 이전에 저장된 기록에는 없으므로 모두 옵셔널이다.

    /// 출전 복장 (도복 / 노기)
    public let competitionUniform: CompetitionUniform?

    /// 출전 체급 (경계 무게와 이하/초과)
    public let competitionWeightLimit: CompetitionWeightLimit?

    /// 앱솔루트(무차별급) 부문 — 한 부문은 체급 또는 앱솔루트 중 하나라, true면 체급은 비어 있다.
    public let competitionAbsolute: Bool

    /// 출전 띠 — 같은 메달이라도 그때 띠에 따라 무게가 달라 대회 당시 띠를 따로 남긴다.
    public let competitionBelt: BeltRank?

    /// 프로필 맨 위 고정(#124) — 가장 자랑하고 싶은 대회가 최신순에 밀려 내려가지 않게 회원이 직접 고른다.
    /// 같은 대회의 여러 부문은 한 줄로 묶여 보이므로, 고정·해제는 묶인 항목 전부에 같은 값을 넣는다.
    public let isPinned: Bool

    public init(
        competitionYear: Int,
        competitionMonth: Int? = nil,
        competitionName: String,
        competitionRank: CompetitionRank,
        competitionUniform: CompetitionUniform? = nil,
        competitionWeightLimit: CompetitionWeightLimit? = nil,
        competitionAbsolute: Bool = false,
        competitionBelt: BeltRank? = nil,
        isPinned: Bool = false
    ) {
        self.competitionYear = competitionYear
        self.competitionMonth = competitionMonth
        self.competitionName = competitionName
        self.competitionRank = competitionRank
        self.competitionUniform = competitionUniform
        self.competitionWeightLimit = competitionWeightLimit
        self.competitionAbsolute = competitionAbsolute
        self.competitionBelt = competitionBelt
        self.isPinned = isPinned
    }

    /// 출전 부문을 하나라도 입력했는지
    public var hasDivision: Bool {
        competitionUniform != nil || competitionWeightLimit != nil || competitionAbsolute || competitionBelt != nil
    }

    /// 고정 여부만 바꾼 사본
    public func settingPinned(_ isPinned: Bool) -> Competition {
        Competition(
            competitionYear: competitionYear,
            competitionMonth: competitionMonth,
            competitionName: competitionName,
            competitionRank: competitionRank,
            competitionUniform: competitionUniform,
            competitionWeightLimit: competitionWeightLimit,
            competitionAbsolute: competitionAbsolute,
            competitionBelt: competitionBelt,
            isPinned: isPinned
        )
    }
}

/// 대회 순위
public enum CompetitionRank: String, Codable, Equatable, Sendable, CaseIterable, Identifiable, Hashable {
    case gold = "GOLD"
    case silver = "SILVER"
    case bronze = "BRONZE"
    case participation = "PARTICIPATION"

    public var id: String { rawValue }

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
