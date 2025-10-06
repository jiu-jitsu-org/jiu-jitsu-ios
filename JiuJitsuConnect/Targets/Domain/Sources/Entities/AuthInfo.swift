//
//  AuthInfo.swift
//  Domain
//
//  Created by suni on 10/6/25.
//

import Foundation

public struct AuthInfo: Equatable {
    public let accessToken: String?
    public let refreshToken: String?
    public let tempToken: String?
    public var isNewUser: Bool {
        return self.tempToken != nil
    }

    public init(accessToken: String?, refreshToken: String?, tempToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tempToken = tempToken
    }
}
