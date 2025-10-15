//
//  AuthResponseDTO.swift
//  Data
//
//  Created by suni on 10/6/25.
//

import Foundation

struct AuthResponseDTO: Decodable, Equatable {
    let isNewUser: Bool?
    let tempToken: String?
    let accessToken: String?
    let refreshToken: String?
    let userInfo: UserInfo?
    
    struct UserInfo: Decodable, Equatable {
        let id: Int
        let email: String?
        let nickname: String?
        let profileImageUrl: String?
        let snsProvider: String?
        let deactivatedWithinGrace: Bool?
    }
}
