//
//  NoticeService.swift
//  Data
//
//  DependencyContainer(App)에서 internal DTO/Endpoint 없이
//  알림 설정 API를 호출할 수 있도록 공개 진입점을 제공한다.
//

import Foundation
import Domain

public final class NoticeService: Sendable {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    public func fetchSetting() async throws -> NoticeSetting {
        let response: NoticeSettingResponseDTO = try await networkService.request(
            endpoint: NoticeEndpoint.getSetting
        )
        return response.toDomain()
    }

    public func updateSetting(_ setting: NoticeSetting) async throws -> NoticeSetting {
        let request = NoticeSettingRequestDTO(
            securityEnabled: setting.securityEnabled,
            serviceEnabled: setting.serviceEnabled,
            communityEnabled: setting.communityEnabled,
            marketingEnabled: setting.marketingEnabled
        )
        let response: NoticeSettingResponseDTO = try await networkService.request(
            endpoint: NoticeEndpoint.updateSetting(request: request)
        )
        return response.toDomain()
    }
}
