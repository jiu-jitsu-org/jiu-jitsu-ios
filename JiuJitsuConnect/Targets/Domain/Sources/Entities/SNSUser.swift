//
//  SNSUser.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public struct SNSUser: Equatable {
    public init(accessToken: String, snsProvider: SNSProvider) {
        self.accessToken = accessToken
        self.snsProvider = snsProvider
    }
    
    public let accessToken: String
    public let snsProvider: SNSProvider
}
