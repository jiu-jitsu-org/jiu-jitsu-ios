//
//  LogoutInfo.swift
//  Domain
//
//  Created by suni on 12/1/25.
//

import Foundation

public struct LogoutInfo: Equatable {
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    public let accessToken: String
    public let refreshToken: String
}
