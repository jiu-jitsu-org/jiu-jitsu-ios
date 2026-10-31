//
//  CommunityPublicProfile.swift
//  Domain
//

import Foundation

/// 다른 회원이 보는 공개 프로필 (`GET /api/community/profile/{userId}`, #116)
///
/// 남이 상대를 판단하는 정보만 담는다 — 현재 체급·성별·특기·지도 정보는 서버가 내려 주지 않는다.
/// 커뮤니티 프로필을 만들지 않은 회원은 닉네임·사진·인증 여부만 있고 나머지는 비어 있다.
public struct CommunityPublicProfile: Equatable, Sendable {
    public let userId: Int
    public let nickname: String
    public let profileImageUrl: String?
    public let academyName: String?
    public let beltRank: BeltRank?
    public let beltStripe: BeltStripe?
    /// 관장/사범 인증 여부 (`OWNER` 역할)
    public let isOwner: Bool
    public let favoritePosition: PositionType?
    public let favoriteTechnique: TechniqueType?
    public let favoriteSubmission: SubmissionType?
    /// 대회명이 있는 기록만, 서버가 정한 순서(고정 → 회원이 정한 순서 → 연도 최신순) 그대로
    public let competitions: [Competition]

    public init(
        userId: Int,
        nickname: String,
        profileImageUrl: String? = nil,
        academyName: String? = nil,
        beltRank: BeltRank? = nil,
        beltStripe: BeltStripe? = nil,
        isOwner: Bool = false,
        favoritePosition: PositionType? = nil,
        favoriteTechnique: TechniqueType? = nil,
        favoriteSubmission: SubmissionType? = nil,
        competitions: [Competition] = []
    ) {
        self.userId = userId
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.academyName = academyName
        self.beltRank = beltRank
        self.beltStripe = beltStripe
        self.isOwner = isOwner
        self.favoritePosition = favoritePosition
        self.favoriteTechnique = favoriteTechnique
        self.favoriteSubmission = favoriteSubmission
        self.competitions = competitions
    }
}
