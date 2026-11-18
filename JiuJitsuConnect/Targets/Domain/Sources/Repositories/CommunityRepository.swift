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

    /// 회원을 신고합니다 (`POST /reports`, reportType USER)
    /// - Parameters:
    ///   - userId: 신고할 회원 ID
    ///   - reason: 신고 사유 코드 (`ABUSE` 등)
    ///   - detail: '기타'로 입력한 내용. 없으면 보내지 않습니다
    /// - Throws: DomainError — 이미 신고한 회원은 `apiError(.alreadyReported)`
    func reportUser(userId: Int, reason: String, detail: String?) async throws

    /// 회원을 차단합니다 (`POST /user/block/{id}`)
    /// - Returns: 서버가 돌려준 차단 상태 (true = 차단)
    /// - Throws: DomainError
    func blockUser(userId: Int) async throws -> Bool

    /// 회원 차단을 해제합니다 (`DELETE /user/block/{id}`)
    /// - Throws: DomainError
    func unblockUser(userId: Int) async throws
}
