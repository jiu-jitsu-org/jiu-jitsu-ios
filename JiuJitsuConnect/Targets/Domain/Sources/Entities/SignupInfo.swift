//
//  SignupInfo.swift
//  Domain
//
//  Created by suni on 11/2/25.
//

import Foundation

public struct SignupInfo: Equatable {
    public let nickname: String
    public let isMarketingAgreed: Bool
    
    public init(nickname: String, isMarketingAgreed: Bool) {
        self.nickname = nickname
        self.isMarketingAgreed = isMarketingAgreed
    }
}
