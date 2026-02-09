//
//  RefreshResponseDTO.swift
//  Data
//
//  Created by suni on 2/9/26.
//

import Foundation

struct RefreshResponseDTO: Decodable, Equatable {
    let isNewUser: Bool?
    let tempToken: String?
    let accessToken: String?
    let refreshToken: String?
    let userInfo: UserInfo?
    
    struct UserInfo: Decodable, Equatable {
        let userId: Int
        let email: String?
        let nickname: String?
        let profileImageUrl: String?
        let snsProvider: String?
        let deactivatedWithinGrace: Bool?
    }
}
