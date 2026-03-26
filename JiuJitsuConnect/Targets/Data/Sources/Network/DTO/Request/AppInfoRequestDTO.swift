//
//  AppInfoRequestDTO.swift
//  Data
//
//

import Foundation
import Domain

struct AppInfoRequestDTO: Encodable {
    let fcmToken: String
    let deviceId: String
    let osType: String
    let osVersion: String
    
    init(info: AppInfo) {
        self.fcmToken = info.fcmToken
        self.deviceId = info.deviceId
        self.osType = info.osType
        self.osVersion = info.osVersion
    }
}
