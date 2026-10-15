//
//  NoticeService.swift
//  Data
//
//  DependencyContainer(App)에서 internal DTO/Endpoint 없이
//  알림 목록·설정 API를 호출할 수 있도록 공개 진입점을 제공한다.
//

import Foundation
import Domain

public final class NoticeService: Sendable {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    /// 안 읽은 알림이 하나라도 있는지. 차단·숨김·신고 대상의 알림은 서버가 목록에서 제외한다(backend#154).
    /// 목록 전체를 받아 판단하는 임시 구현으로, 목록이 페이징되면 틀려진다.
    /// 안 읽은 수 전용 API(backend#155)가 나오면 교체한다(#47).
    public func hasUnread() async throws -> Bool {
        let response: [NoticeListResponseDTO] = try await networkService.request(
            endpoint: NoticeEndpoint.getList
        )
        return response.contains { !$0.isRead }
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
