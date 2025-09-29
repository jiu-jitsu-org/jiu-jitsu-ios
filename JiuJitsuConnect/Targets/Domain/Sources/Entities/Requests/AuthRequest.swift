//
//  AuthRequest.swift
//  Domain
//
//  Created by suni on 9/29/25.
//

import Foundation

public struct AuthRequest: Encodable, Sendable {
    public let accessToken: String
    public let provider: SNSProvider
    
    public init(accessToken: String, provider: SNSProvider) {
        self.accessToken = accessToken
        self.provider = provider
    }
    
}
