//
//  AuthInfo.swift
//  Domain
//
//  Created by suni on 10/6/25.
//

import Foundation

public struct AuthInfo: Equatable, Sendable {
    public let accessToken: String?
    public let refreshToken: String?
    public let tempToken: String?
    public let isNewUser: Bool?
    public let userInfo: UserInfo?
    
    public var isGuest: Bool { accessToken == nil }
    
    public struct UserInfo: Equatable, Sendable {
        public let userId: Int
        public let email: String?
        public let nickname: String?
        public let profileImageUrl: String?
        public let snsProvider: String?
        public let deactivatedWithinGrace: Bool?
        
        public init(userId: Int, email: String?, nickname: String?, profileImageUrl: String?, snsProvider: String?, deactivatedWithinGrace: Bool?) {
            self.userId = userId
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

public extension AuthInfo {
    static var guest: AuthInfo {
        // 토큰이 nil이거나 비어있는 게스트용 객체 생성
        AuthInfo(accessToken: nil, refreshToken: nil, tempToken: nil, isNewUser: false, userInfo: nil)
    }
}
