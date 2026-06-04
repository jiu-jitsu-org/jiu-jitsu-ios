//
//  ImageRepositoryImpl.swift
//  Data
//
//  Created by suni on 6/4/26.
//

import Foundation
import Domain
import CoreKit

/// 서버 측 이미지 레코드 관리 `ImageRepository` 구현.
///
/// CDN 업로드는 `ImageUploadRepositoryImpl`이 담당하고, 본 구현은 그 결과를
/// BE에 등록(`POST /api/image`)·삭제(`DELETE /api/image/{id}`)한다.
public final class ImageRepositoryImpl: ImageRepository {
    private let networkService: NetworkService

    public init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
    }

    public func registerImage(cdnId: String, imageUrl: String) async throws -> RegisteredImage {
        do {
            let requestDTO = RegisterImageRequestDTO(cdnId: cdnId, imageUrl: imageUrl)
            let endpoint = ImageEndpoint.register(request: requestDTO)
            let responseDTO: RegisterImageResponseDTO = try await networkService.request(endpoint: endpoint)
            return responseDTO.toDomain()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func deleteImage(id: Int64) async throws {
        do {
            let endpoint = ImageEndpoint.delete(id: id)
            try await networkService.requestVoid(endpoint: endpoint)
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
}
