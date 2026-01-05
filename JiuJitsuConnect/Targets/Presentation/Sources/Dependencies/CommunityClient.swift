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
    public var updateProfile: @Sendable (CommunityProfile) async throws -> CommunityProfile
    
    public init(
        fetchProfile: @escaping @Sendable () async throws -> CommunityProfile,
        updateProfile: @escaping @Sendable (CommunityProfile) async throws -> CommunityProfile
    ) {
        self.fetchProfile = fetchProfile
        self.updateProfile = updateProfile
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
        updateProfile: { update in
            update
        }
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
        updateProfile: { profile in
            // 프리뷰에서는 그대로 반환
            profile
        }
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
        updateProfile: { _ in
            fatalError("CommunityClient.updateProfile is not implemented")
        }
    )
}
