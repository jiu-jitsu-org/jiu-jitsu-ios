//
//  NoticeSettingResponseDTO.swift
//  Data
//

import Foundation
import Domain

struct NoticeSettingResponseDTO: Decodable, Sendable {
    let securityEnabled: Bool
    let serviceEnabled: Bool
    let communityEnabled: Bool
    let marketingEnabled: Bool

    func toDomain() -> NoticeSetting {
        NoticeSetting(
            securityEnabled: securityEnabled,
            serviceEnabled: serviceEnabled,
            communityEnabled: communityEnabled,
            marketingEnabled: marketingEnabled
        )
    }
}
