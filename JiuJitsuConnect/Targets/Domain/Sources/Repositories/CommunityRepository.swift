//
//  CommunityRepository.swift
//  Domain
//
//  Created by suni on 1/5/26.
//

import Foundation

/// 커뮤니티 관련 데이터 작업을 위한 Repository 프로토콜
public protocol CommunityRepository: Sendable {
    /// 사용자의 커뮤니티 프로필 정보를 가져옵니다 
    /// - Returns: 커뮤니티 프로필 정보
    /// - Throws: DomainError
    func fetchProfile() async throws -> CommunityProfile
    
    /// 사용자의 커뮤니티 프로필 정보를 업데이트합니다
    /// - Parameter profile: 업데이트할 프로필 정보
    /// - Returns: 업데이트된 프로필 정보
    /// - Throws: DomainError
    func updateProfile(_ profile: CommunityProfile, section: ProfileSection) async throws -> CommunityProfile

    /// 다른 회원의 공개 프로필을 가져옵니다
    /// - Parameter userId: 글·댓글 작성자 ID
    /// - Returns: 공개 프로필 (체급·성별·특기 제외)
    /// - Throws: DomainError — 없는 회원·탈퇴한 회원은 `apiError(.userNotFound)`
    func fetchPublicProfile(userId: Int) async throws -> CommunityPublicProfile
}
