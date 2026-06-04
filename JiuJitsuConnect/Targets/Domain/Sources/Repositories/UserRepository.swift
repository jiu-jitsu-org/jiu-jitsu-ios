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
    /// 프로필 이미지 설정 (PUT `/api/user/profile/image`).
    ///
    /// 서버 등록(`POST /api/image`)으로 발급된 이미지 파일 id를 `imageFileId` 쿼리 파라미터로 전달한다.
    /// (이미지 삭제는 별도 `ImageRepository.deleteImage(id:)` 경로를 사용한다.)
    func setProfileImage(imageFileId: Int64) async throws -> Bool
    /// 관장/사범 인증 요청 (PUT `/api/user/owner`).
    ///
    /// 서버 등록으로 발급된 인증 이미지 파일 id를 `imageFileId` 쿼리 파라미터로 전달해 권한 요청을 등록한다.
    func requestOwnerVerification(imageFileId: Int64) async throws -> Bool
}
