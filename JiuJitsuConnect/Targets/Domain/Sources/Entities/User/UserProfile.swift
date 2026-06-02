//
//  UserProfile.swift
//  Domain
//
//  Created by suni on 6/2/26.
//

import Foundation

/// 사용자 계정 역할.
public enum UserRole: String, Equatable, Sendable {
    /// 일반 회원 (기본값)
    case user = "USER"
    /// 관장/사범 인증 완료 회원
    case owner = "OWNER"
    /// 관리자
    case admin = "ADMIN"
}

/// user-level 프로필 (GET `/api/user/profile`).
///
/// 커뮤니티 프로필(`CommunityProfile`)이 BJJ 활동 정보를 담는 것과 달리,
/// 계정 식별/권한/관장사범 인증 상태 같은 user-level 정보를 담는다.
public struct UserProfile: Equatable, Sendable {
    public let userId: Int
    public let email: String?
    public let nickname: String?
    public let profileImageUrl: String?
    public let snsProvider: String?
    /// 관장/사범 인증 요청 여부. `true`면 이미 인증을 신청해 검토 대기/완료 상태.
    public let ownerRequested: Bool
    /// 인증 요청 시 제출한 이미지 URL. 미제출/기본값은 Data 레이어에서 `nil`로 정규화된다.
    public let ownerRequestImageUrl: String?
    public let role: String?
    public let status: String?

    /// BE `role` 문자열을 타입 안전한 `UserRole`로 변환.
    /// 알 수 없는 값은 `.user`(기본값)로 처리해 UI가 깨지지 않도록 한다.
    public var userRole: UserRole {
        UserRole(rawValue: role ?? "") ?? .user
    }

    public init(
        userId: Int,
        email: String? = nil,
        nickname: String? = nil,
        profileImageUrl: String? = nil,
        snsProvider: String? = nil,
        ownerRequested: Bool = false,
        ownerRequestImageUrl: String? = nil,
        role: String? = nil,
        status: String? = nil
    ) {
        self.userId = userId
        self.email = email
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.snsProvider = snsProvider
        self.ownerRequested = ownerRequested
        self.ownerRequestImageUrl = ownerRequestImageUrl
        self.role = role
        self.status = status
    }
}
