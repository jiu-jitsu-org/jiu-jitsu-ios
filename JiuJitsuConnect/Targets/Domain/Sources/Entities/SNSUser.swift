//
//  SNSUser.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public struct SNSUser: Equatable {
    public init(id: String, idToken: String, email: String, nickname: String, snsProvider: String) {
        self.id = id
        self.idToken = idToken
        self.email = email
        self.nickname = nickname
        self.snsProvider = snsProvider
    }
    
    public let id: String
    public let idToken: String
    public let email: String
    public let nickname: String
    public let snsProvider: String
}
