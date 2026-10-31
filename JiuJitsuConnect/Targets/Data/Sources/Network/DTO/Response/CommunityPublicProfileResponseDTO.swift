//
//  CommunityPublicProfileResponseDTO.swift
//  Data
//

import Foundation
import Domain

/// 다른 회원 공개 프로필 응답 DTO (`GET /api/community/profile/{userId}`)
///
/// `medalCount`도 내려오지만 공개 기록(대회명 있는 기록)만 오므로 화면이 목록에서 직접 센다.
struct CommunityPublicProfileResponseDTO: Decodable {
    let userId: Int
    let nickname: String
    let profileImage: ImageRefDTO?
    let academyName: String?
    let beltRank: String?
    let beltStripe: String?
    let isOwner: Bool?
    let favoritePosition: String?
    let favoriteTechnique: String?
    let favoriteSubmission: String?
    let competitions: [CompetitionDTO]?

    func toDomain() -> CommunityPublicProfile {
        CommunityPublicProfile(
            userId: userId,
            nickname: nickname,
            profileImageUrl: ProfileImageSentinel.normalize(profileImage?.imageUrl),
            academyName: academyName.flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 },
            beltRank: beltRank.flatMap { BeltRank(rawValue: $0) },
            beltStripe: beltStripe.flatMap { BeltStripe(rawValue: $0) },
            isOwner: isOwner ?? false,
            favoritePosition: favoritePosition.flatMap { PositionType(rawValue: $0) },
            favoriteTechnique: favoriteTechnique.flatMap { TechniqueType(rawValue: $0) },
            favoriteSubmission: favoriteSubmission.flatMap { SubmissionType(rawValue: $0) },
            competitions: competitions?.flatMap { $0.toDomain() } ?? []
        )
    }
}
