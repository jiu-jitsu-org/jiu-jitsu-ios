//
//  AppInfo.swift
//  Domain
//
//

import Foundation

public struct AppInfo: Equatable, Sendable {
    public let fcmToken: String
    public let deviceId: String
    public let osType: String
    public let osVersion: String
    
    public init(fcmToken: String, deviceId: String, osType: String, osVersion: String) {
        self.fcmToken = fcmToken
        self.deviceId = deviceId
        self.osType = osType
        self.osVersion = osVersion
    }
}
