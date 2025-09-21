//
//  User.swift
//  App
//
//  Created by suni on 9/21/25.
//

import Foundation

public struct User: Equatable {
    
    public init(id: String, email: String, nickname: String, snsProvider: String, role: String, status: String) {
        self.id = id
        self.email = email
        self.nickname = nickname
        self.snsProvider = snsProvider
        self.role = role
        self.status = status
    }
    
    public let id: String
    public let email: String
    public let nickname: String
    public let snsProvider: String
    public let role: String
    public let status: String
}
