//
//  SignupInfo.swift
//  Domain
//
//  Created by suni on 11/2/25.
//

import Foundation

public struct SignupInfo: Equatable {
    public let tempToken: String
    public let nickname: String
    public let isMarketingAgreed: Bool
    
    public init(tempToken: String, nickname: String, isMarketingAgreed: Bool) {
        self.tempToken = tempToken
        self.nickname = nickname
        self.isMarketingAgreed = isMarketingAgreed
    }
}
