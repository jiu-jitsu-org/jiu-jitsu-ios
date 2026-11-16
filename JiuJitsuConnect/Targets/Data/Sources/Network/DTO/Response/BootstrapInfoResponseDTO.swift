//
//  BootstrapInfoResponseDTO.swift
//  Data
//

import Foundation
import Domain

struct BootstrapInfoResponseDTO: Decodable, Sendable {
    let appVersionInfo: AppVersionInfoDTO

    struct AppVersionInfoDTO: Decodable, Sendable {
        let minVersion: String
        let nowVersion: String
    }

    func toDomain() -> AppVersionPolicy {
        AppVersionPolicy(minimumVersion: appVersionInfo.minVersion, latestVersion: appVersionInfo.nowVersion)
    }
}
