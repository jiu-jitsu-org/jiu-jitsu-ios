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

/// 관장/사범 인증 신청 상태 (`ownerVerification`).
public struct OwnerVerification: Equatable, Sendable {
    public enum Status: String, Equatable, Sendable {
        /// 신청한 적 없음
        case notRequested = "NONE"
        /// 심사 중. 다시 신청하면 서류만 교체된다.
        case pending = "PENDING"
        /// 승인됨 → `role = OWNER`
        case approved = "APPROVED"
        /// 거절됨. 다시 신청할 수 있다.
        case rejected = "REJECTED"
    }

    public let status: Status
    /// 제출한 인증 서류 이미지 URL. 미제출/기본값은 Data 레이어에서 `nil`로 정규화된다.
    public let documentImageUrl: String?
    /// 거절 사유. 관리자가 남기지 않으면 `nil`.
    public let rejectReason: String?

    public init(status: Status, documentImageUrl: String? = nil, rejectReason: String? = nil) {
        self.status = status
        self.documentImageUrl = documentImageUrl
        self.rejectReason = rejectReason
    }

    public static let notRequested = OwnerVerification(status: .notRequested)
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
    /// 현재 프로필 이미지의 서버 파일 id. 삭제(`DELETE /api/image/{id}`)에 사용한다.
    /// BE 프로필 응답이 내려줄 때만 채워지며, 없으면 `nil`(삭제 불가).
    public let profileImageFileId: Int64?
    public let snsProvider: String?
    /// 관장/사범 인증 신청 상태.
    public let ownerVerification: OwnerVerification
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
        profileImageFileId: Int64? = nil,
        snsProvider: String? = nil,
        ownerVerification: OwnerVerification = .notRequested,
        role: String? = nil,
        status: String? = nil
    ) {
        self.userId = userId
        self.email = email
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.profileImageFileId = profileImageFileId
        self.snsProvider = snsProvider
        self.ownerVerification = ownerVerification
        self.role = role
        self.status = status
    }

    /// 실제로 렌더링 가능한 프로필 이미지 URL이 설정되어 있는지 여부.
    ///
    /// 헤더의 이미지 표시 조건과 동일한 기준(빈 문자열 제외 + http/https URL 유효성)을 적용해,
    /// "이미지가 보이는 상태"와 "삭제 옵션 노출" 같이 UI 결정이 어긋나지 않도록 단일 소스로 사용한다.
    public var hasProfileImage: Bool {
        guard let urlString = profileImageUrl,
              !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme == "https" || url.scheme == "http"
        else { return false }
        return true
    }

    /// 프로필 이미지 URL·파일 id 업데이트 (둘 다 `nil` 전달 시 삭제 의미)
    public func updatingProfileImage(url: String?, fileId: Int64?) -> UserProfile {
        UserProfile(
            userId: userId,
            email: email,
            nickname: nickname,
            profileImageUrl: url,
            profileImageFileId: fileId,
            snsProvider: snsProvider,
            ownerVerification: ownerVerification,
            role: role,
            status: status
        )
    }

    /// 인증 신청 상태만 바꾼 사본 (사진 제출 직후 낙관적 반영용)
    public func updatingOwnerVerification(_ ownerVerification: OwnerVerification) -> UserProfile {
        UserProfile(
            userId: userId,
            email: email,
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            profileImageFileId: profileImageFileId,
            snsProvider: snsProvider,
            ownerVerification: ownerVerification,
            role: role,
            status: status
        )
    }
}
