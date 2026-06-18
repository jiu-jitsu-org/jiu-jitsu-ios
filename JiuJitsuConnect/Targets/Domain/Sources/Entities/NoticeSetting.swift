//
//  NoticeSetting.swift
//  Domain
//

import Foundation

public struct NoticeSetting: Equatable, Sendable {
    public let securityEnabled: Bool
    public let serviceEnabled: Bool
    public let communityEnabled: Bool
    public let marketingEnabled: Bool

    public init(
        securityEnabled: Bool,
        serviceEnabled: Bool,
        communityEnabled: Bool,
        marketingEnabled: Bool
    ) {
        self.securityEnabled = securityEnabled
        self.serviceEnabled = serviceEnabled
        self.communityEnabled = communityEnabled
        self.marketingEnabled = marketingEnabled
    }
}
