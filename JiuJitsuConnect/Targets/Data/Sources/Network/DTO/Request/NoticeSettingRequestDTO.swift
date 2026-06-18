//
//  NoticeSettingRequestDTO.swift
//  Data
//

import Foundation

struct NoticeSettingRequestDTO: Encodable, Sendable {
    let securityEnabled: Bool
    let serviceEnabled: Bool
    let communityEnabled: Bool
    let marketingEnabled: Bool
}
