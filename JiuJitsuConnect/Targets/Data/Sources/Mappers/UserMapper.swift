//
//  UserMapper.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation
import Domain

// MARK: - Domain To DTO
extension SignupRequestDTO {
    init(info: SignupInfo) {
        self.nickname = info.nickname
        self.isMarketingAgreed = info.isMarketingAgreed
    }
}

extension CheckNicknameRequestDTO {
    init(info: CheckNicknameInfo) {
        self.nickname = info.nickname
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
            userId: self.userId,
            email: self.email,
            nickname: self.nickname,
            profileImageUrl: self.profileImageUrl,
            snsProvider: self.snsProvider,
            deactivatedWithinGrace: self.deactivatedWithinGrace
        )
    }
}
