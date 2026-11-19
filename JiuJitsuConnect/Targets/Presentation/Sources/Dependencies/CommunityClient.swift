//
//  CommunityClient.swift
//  CoreKit
//
//  Created by suni on 1/5/26.
//

import ComposableArchitecture
import Domain

public struct CommunityClient: Sendable {
    /// 프로필 정보를 가져오는 클로저
    public var fetchProfile: @Sendable () async throws -> CommunityProfile
    
    /// 프로필 정보를 업데이트하는 클로저
    /// - Parameters:
    ///   - profile: 업데이트할 프로필 정보
    ///   - section: 업데이트할 섹션 (기본값: .academy)
    public var updateProfile: @Sendable (CommunityProfile, ProfileSection) async throws -> CommunityProfile

    /// 다른 회원의 공개 프로필을 가져오는 클로저 (#116)
    public var fetchPublicProfile: @Sendable (Int) async throws -> CommunityPublicProfile

    /// 회원 신고 — (회원 id, 사유 코드, '기타' 입력) (#328)
    public var reportUser: @Sendable (Int, String, String?) async throws -> Void

    /// 회원 차단 — 서버가 돌려준 차단 상태 (#328)
    public var blockUser: @Sendable (Int) async throws -> Bool

    /// 회원 차단 해제 (#328)
    public var unblockUser: @Sendable (Int) async throws -> Void
    
    public init(
        fetchProfile: @Sendable @escaping () async throws -> CommunityProfile,
        updateProfile: @Sendable @escaping (CommunityProfile, ProfileSection) async throws -> CommunityProfile,
        fetchPublicProfile: @Sendable @escaping (Int) async throws -> CommunityPublicProfile,
        reportUser: @Sendable @escaping (Int, String, String?) async throws -> Void,
        blockUser: @Sendable @escaping (Int) async throws -> Bool,
        unblockUser: @Sendable @escaping (Int) async throws -> Void
    ) {
        self.fetchProfile = fetchProfile
        self.updateProfile = updateProfile
        self.fetchPublicProfile = fetchPublicProfile
        self.reportUser = reportUser
        self.blockUser = blockUser
        self.unblockUser = unblockUser
    }
}

// MARK: - DependencyKey

extension CommunityClient: DependencyKey {
    public static let liveValue: Self = .unimplemented
    
    /// Test 구현 (테스트용 Mock)
    public static let testValue: CommunityClient = CommunityClient(
        fetchProfile: {
            CommunityProfile(
                nickname: "홍길동",
                profileImageUrl: "https://example.com/profile.jpg",
                beltRank: .blue,
                beltStripe: .two,
                gender: .male,
                weightKg: 76.5,
                academyName: "Gracie Barra Seoul",
                competitions: [
                    Competition(
                        competitionYear: 2024,
                        competitionMonth: 12,
                        competitionName: "서울 주짓수 챔피언십",
                        competitionRank: .gold
                    ),
                    Competition(
                        competitionYear: 2024,
                        competitionMonth: 6,
                        competitionName: "전국 주짓수 대회",
                        competitionRank: .silver
                    )
                ],
                bestSubmission: .chokes,
                favoriteSubmission: .armLocks,
                bestTechnique: .sweeps,
                favoriteTechnique: .guardPasses,
                bestPosition: .top,
                favoritePosition: .guard,
                isWeightHidden: false,
                isOwner: true,
                teachingPhilosophy: "기본기를 탄탄히, 안전하게 훈련하는 것을 최우선으로 합니다.",
                teachingStartDate: "2020-03-15",
                teachingDetail: "10년 이상의 주짓수 경력과 5년의 지도 경력을 보유하고 있습니다."
            )
        },
        updateProfile: { update, _ in
            update
        },
        fetchPublicProfile: { _ in .preview },
        reportUser: { _, _, _ in },
        blockUser: { _ in true },
        unblockUser: { _ in }
    )
    /// Preview 구현 (SwiftUI 프리뷰용)
    public static let previewValue: CommunityClient = CommunityClient(
        fetchProfile: {
            // 프리뷰용 Mock 데이터
            CommunityProfile(
                nickname: "홍길동",
                profileImageUrl: "https://example.com/profile.jpg",
                beltRank: .blue,
                beltStripe: .two,
                gender: .male,
                weightKg: 76.5,
                academyName: "Gracie Barra Seoul",
                competitions: [
                    Competition(
                        competitionYear: 2024,
                        competitionMonth: 12,
                        competitionName: "서울 주짓수 챔피언십",
                        competitionRank: .gold
                    ),
                    Competition(
                        competitionYear: 2024,
                        competitionMonth: 6,
                        competitionName: "전국 주짓수 대회",
                        competitionRank: .silver
                    )
                ],
                bestSubmission: .chokes,
                favoriteSubmission: .armLocks,
                bestTechnique: .sweeps,
                favoriteTechnique: .guardPasses,
                bestPosition: .top,
                favoritePosition: .guard,
                isWeightHidden: false,
                isOwner: true,
                teachingPhilosophy: "기본기를 탄탄히, 안전하게 훈련하는 것을 최우선으로 합니다.",
                teachingStartDate: "2020-03-15",
                teachingDetail: "10년 이상의 주짓수 경력과 5년의 지도 경력을 보유하고 있습니다."
            )
        },
        updateProfile: { profile, _ in
            // 프리뷰에서는 그대로 반환
            profile
        },
        fetchPublicProfile: { _ in .preview },
        reportUser: { _, _, _ in },
        blockUser: { _ in true },
        unblockUser: { _ in }
    )
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    /// CommunityClient에 접근하기 위한 computed property
    public var communityClient: CommunityClient {
        get { self[CommunityClient.self] }
        set { self[CommunityClient.self] = newValue }
    }
}


extension CommunityClient {
    static let unimplemented: Self = Self(
        fetchProfile: {
            fatalError("CommunityClient.fetchProfile is not implemented")
        },
        updateProfile: { _, _ in
            fatalError("CommunityClient.updateProfile is not implemented")
        },
        fetchPublicProfile: { _ in
            fatalError("CommunityClient.fetchPublicProfile is not implemented")
        },
        reportUser: { _, _, _ in
            fatalError("CommunityClient.reportUser is not implemented")
        },
        blockUser: { _ in
            fatalError("CommunityClient.blockUser is not implemented")
        },
        unblockUser: { _ in
            fatalError("CommunityClient.unblockUser is not implemented")
        }
    )
}

extension CommunityPublicProfile {
    /// 프리뷰·테스트용 공개 프로필
    static let preview = CommunityPublicProfile(
        userId: 101,
        nickname: "암바장인곰",
        academyName: "OSS 주짓수 강남",
        beltRank: .black,
        beltStripe: .two,
        isOwner: true,
        favoritePosition: .guard,
        favoriteTechnique: .sweeps,
        favoriteSubmission: .chokes,
        competitions: [
            Competition(competitionYear: 2026, competitionName: "서울 오픈", competitionRank: .silver, competitionBelt: .black),
            Competition(competitionYear: 2025, competitionName: "전국 주짓수 선수권", competitionRank: .gold, competitionBelt: .brown)
        ]
    )
}
