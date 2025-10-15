//
//  AuthInfo.swift
//  Domain
//
//  Created by suni on 10/6/25.
//

import Foundation

public struct AuthInfo: Equatable {
    public let accessToken: String?
    public let refreshToken: String?
    public let tempToken: String?
    public let isNewUser: Bool?
    public let userInfo: UserInfo?
    
    public struct UserInfo: Equatable {
        public let id: Int
        public let email: String?
        public let nickname: String?
        public let profileImageUrl: String?
        public let snsProvider: String?
        public let deactivatedWithinGrace: Bool?
        
        public init(id: Int, email: String?, nickname: String?, profileImageUrl: String?, snsProvider: String?, deactivatedWithinGrace: Bool?) {
            self.id = id
            self.email = email
            self.nickname = nickname
            self.profileImageUrl = profileImageUrl
            self.snsProvider = snsProvider
            self.deactivatedWithinGrace = deactivatedWithinGrace
        }
    }
    
    public init(accessToken: String?, refreshToken: String?, tempToken: String?, isNewUser: Bool?, userInfo: UserInfo?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tempToken = tempToken
        self.isNewUser = isNewUser
        self.userInfo = userInfo
    }
}
