//
//  UserRepository.swift
//  Domain
//
//  Created by suni on 11/2/25.
//

import Foundation

public protocol UserRepository: Sendable {
    func signup(info: SignupInfo) async throws -> AuthInfo
    func checkNickname(info: CheckNicknameInfo) async throws -> Bool
    func withdrawal() async throws -> Bool
    /// 사용자 프로필 조회 (GET `/api/user/profile`).
    func fetchUserProfile() async throws -> UserProfile
    /// 회원 앱 정보 등록 (POST `/api/user/appInfo` — FCM 토큰·디바이스 등)
    func registerAppInfo(info: AppInfo) async throws -> Bool
    /// 닉네임 단독 수정 (PUT `/api/user/profile/nickname`).
    func updateNickname(_ nickname: String) async throws -> Bool
    /// 프로필 이미지 URL 갱신/삭제 (PUT `/api/user/profile/image`).
    ///
    /// `nil` 전달 시 "이미지 삭제" 의도 — Data 레이어에서 BE 합의 sentinel로 매핑되어
    /// 같은 엔드포인트의 쿼리 파라미터로 전달된다.
    func updateProfileImage(_ profileImageUrl: String?) async throws -> Bool
    /// 관장/사범 인증 요청 (PUT `/api/user/owner`).
    ///
    /// 인증 이미지 URL(ImageKit 호스팅)을 imageUrl 쿼리 파라미터로 전달해 권한 요청을 등록한다.
    func requestOwnerVerification(imageUrl: String) async throws -> Bool
}
