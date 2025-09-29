//
//  SNSUser.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public struct SNSUser: Equatable {
    public init(idToken: String, snsProvider: SNSProvider) {
        self.idToken = idToken
        self.snsProvider = snsProvider
    }
    
    public let idToken: String
    public let snsProvider: SNSProvider
}
