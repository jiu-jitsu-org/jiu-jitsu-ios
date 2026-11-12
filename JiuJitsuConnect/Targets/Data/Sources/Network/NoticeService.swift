//
//  NoticeService.swift
//  Data
//
//  DependencyContainer(App)에서 internal DTO/Endpoint 없이
//  안 읽은 알림 수·알림 설정 API를 호출할 수 있도록 공개 진입점을 제공한다.
//

import Foundation
import Domain

public final class NoticeService: Sendable {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    /// 안 읽은 알림이 하나라도 있는지. 집계 기준은 알림 목록과 같다(차단·숨김·신고 대상 제외, backend#155).
    public func hasUnread() async throws -> Bool {
        let count: Int64 = try await networkService.request(
            endpoint: NoticeEndpoint.getUnreadCount
        )
        return count > 0
    }

    public func fetchSetting() async throws -> NoticeSetting {
        let response: NoticeSettingResponseDTO = try await networkService.request(
            endpoint: NoticeEndpoint.getSetting
        )
        return response.toDomain()
    }

    public func updateSetting(_ setting: NoticeSettingUpdate) async throws -> NoticeSetting {
        let request = NoticeSettingRequestDTO(
            securityEnabled: setting.securityEnabled,
            serviceEnabled: setting.serviceEnabled,
            communityEnabled: setting.communityEnabled,
            marketingEnabled: setting.marketingEnabled,
            competitionEnabled: setting.competitionEnabled
        )
        let response: NoticeSettingResponseDTO = try await networkService.request(
            endpoint: NoticeEndpoint.updateSetting(request: request)
        )
        return response.toDomain()
    }
}
