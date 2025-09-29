//
//  AuthResponse.swift
//  Domain
//
//  Created by suni on 9/29/25.
//

import Foundation

public struct AuthResponse: Decodable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let userInfo: UserInfo
    
    public init(accessToken: String, refreshToken: String, userInfo: UserInfo) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userInfo = userInfo
    }
    
    public struct UserInfo: Decodable, Equatable {
        public let id: Int
        public let email: String?
        public let nickname: String
        public let profileImageUrl: String?
        public let snsProvider: String
        public let deactivatedWithinGrace: Bool
        
        public init(id: Int, email: String?, nickname: String, profileImageUrl: String?, snsProvider: String, deactivatedWithinGrace: Bool) {
            self.id = id
            self.email = email
            self.nickname = nickname
            self.profileImageUrl = profileImageUrl
            self.snsProvider = snsProvider
            self.deactivatedWithinGrace = deactivatedWithinGrace
        }
    }

}
