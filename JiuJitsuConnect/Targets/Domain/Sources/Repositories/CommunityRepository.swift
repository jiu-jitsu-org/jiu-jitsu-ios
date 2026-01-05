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
    func postProfile(_ profile: CommunityProfile) async throws -> CommunityProfile
}
