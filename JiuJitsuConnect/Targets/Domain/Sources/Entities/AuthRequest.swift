//
//  AuthRequest.swift
//  Domain
//
//  Created by suni on 9/29/25.
//

import Foundation

public struct AuthRequest: Encodable, Sendable {
    public let accessToken: String
    public let snsProvider: SNSProvider
    
    public init(accessToken: String, snsProvider: SNSProvider) {
        self.accessToken = accessToken
        self.snsProvider = snsProvider
    }
    
}
