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
    /// 회원 앱 정보 등록 (POST `/api/user/appInfo` — FCM 토큰·디바이스 등)
    func registerAppInfo(info: AppInfo) async throws -> Bool
    /// 사용자 프로필 갱신 (PUT `/api/user/profile`).
    ///
    /// BE가 PUT 전체 교체 시맨틱이라 nickname은 항상 현재값/새 값을 전달한다.
    /// `profileImageUrl = nil`은 JSON `null`로 직렬화되어 "이미지 삭제" 의도를 명시한다.
    func updateProfile(nickname: String, profileImageUrl: String?) async throws -> Bool
    /// 닉네임 단독 수정 (PUT `/api/user/profile/nickname`).
    ///
    /// 쿼리 파라미터로 nickname만 전달한다.
    func updateNickname(_ nickname: String) async throws -> Bool
}
