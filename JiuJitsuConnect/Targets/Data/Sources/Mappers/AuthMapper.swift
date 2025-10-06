//
//  AuthMapper.swift
//  Data
//
//  Created by suni on 10/6/25.
//

import Foundation
import Domain

// MARK: - Domain To DTO
extension SNSUser {
    func toRequestDTO() -> AuthRequestDTO {
        return AuthRequestDTO(
            accessToken: self.accessToken,
            provider: self.snsProvider.rawValue
        )
    }
}

// MARK: - DTO to Domain
extension AuthResponseDTO {
    func toDomain() -> AuthInfo {
        return AuthInfo(
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            tempToken: self.tempToken
        )
    }
}
