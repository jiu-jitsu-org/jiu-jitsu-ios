//
//  AuthRequest.swift
//  Domain
//
//  Created by suni on 9/29/25.
//

public struct AuthRequest: Encodable, Sendable {
    public let idToken: String
    public let provider: SNSProvider
}
