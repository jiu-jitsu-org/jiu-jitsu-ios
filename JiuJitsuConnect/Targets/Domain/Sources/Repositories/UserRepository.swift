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
}
