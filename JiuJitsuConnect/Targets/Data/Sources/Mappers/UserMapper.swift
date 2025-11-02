//
//  UserMapper.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation
import Domain

// MARK: - Domain To DTO
extension SignupInfo {
    func toRequestDTO() -> SignupRequestDTO {
        return SignupRequestDTO(
            nickname: self.nickname,
            isMarketingAgreed: self.isMarketingAgreed
        )
    }
}

// MARK: - DTO to Domain
extension SignupResponseDTO {
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

extension SignupResponseDTO.UserInfo {
    func toDomain() -> AuthInfo.UserInfo {
        return AuthInfo.UserInfo(
            id: self.userId,
            email: self.email,
            nickname: self.nickname,
            profileImageUrl: self.profileImageUrl,
            snsProvider: self.snsProvider,
            deactivatedWithinGrace: self.deactivatedWithinGrace
        )
    }
}
