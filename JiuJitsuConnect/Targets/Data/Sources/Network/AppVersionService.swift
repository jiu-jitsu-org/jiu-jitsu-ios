//
//  AppVersionService.swift
//  Data
//
//  DependencyContainer(App)에서 internal DTO/Endpoint 없이
//  앱 최소 · 최신 버전 API를 호출할 수 있도록 공개 진입점을 제공한다(#326).
//

import Foundation
import Domain

public final class AppVersionService: Sendable {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    public func fetchPolicy() async throws -> AppVersionPolicy {
        let response: BootstrapInfoResponseDTO = try await networkService.request(
            endpoint: BootstrapEndpoint.getInfo(osName: "IOS")
        )
        return response.toDomain()
    }
}
