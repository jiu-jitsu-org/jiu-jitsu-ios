//
//  AuthMapper.swift
//  Data
//
//  Created by suni on 10/6/25.
//

import Foundation
import Domain

// MARK: - Domain To DTO
extension LoginRequestDTO {
    init(user: SNSUser) {
        self.accessToken = user.accessToken
        self.snsProvider = user.snsProvider.rawValue
    }
}

// MARK: - DTO to Domain
extension LoginResponseDTO {
    func toDomain() -> AuthInfo {
        return AuthInfo(
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            tempToken: self.tempToken,
            isNewUser: self.isNewUser,
            userInfo: self.userInfo?.toDomain()
        )
    }
}

extension LoginResponseDTO.UserInfo {
    func toDomain() -> AuthInfo.UserInfo {
        return AuthInfo.UserInfo(
            userId: self.userId,
            email: self.email,
            nickname: self.nickname,
            profileImageUrl: self.profileImageUrl,
            snsProvider: self.snsProvider,
            deactivatedWithinGrace: self.deactivatedWithinGrace
        )
    }
}

extension RefreshResponseDTO {
    func toDomain() -> AuthInfo {
        return AuthInfo(
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            tempToken: self.tempToken,
            isNewUser: self.isNewUser,
            userInfo: self.userInfo?.toDomain()
        )
    }
}

extension RefreshResponseDTO.UserInfo {
    func toDomain() -> AuthInfo.UserInfo {
        return AuthInfo.UserInfo(
            userId: self.userId,
            email: self.email,
            nickname: self.nickname,
            profileImageUrl: self.profileImageUrl,
            snsProvider: self.snsProvider,
            deactivatedWithinGrace: self.deactivatedWithinGrace
        )
    }
}
