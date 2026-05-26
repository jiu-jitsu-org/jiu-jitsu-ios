//
//  ImageUploadRepositoryImpl.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation
import Domain
import CoreKit

/// ImageKit 기반 `ImageUploadRepository` 구현.
///
/// 흐름:
/// 1. 우리 BE의 `/api/imagekit/auth`로부터 `token`/`expire`/`signature` 발급
/// 2. multipart 본문 구성
/// 3. `upload.imagekit.io/api/v1/files/upload`에 직접 업로드 → 호스팅된 URL 반환
public final class ImageUploadRepositoryImpl: ImageUploadRepository {

    private let networkService: NetworkService
    private let decoder: JSONDecoder

    public init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
        // ImageKit 응답은 camelCase로 옴 — convertFromSnakeCase는 사실상 no-op (안전)
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = d
    }

    public func uploadProfileImage(_ data: Data) async throws -> String {
        do {
            // 0) 업로드 페이로드 정규화 — 1024px 다운샘플 + JPEG 0.8 재인코딩.
            //    원본 풀해상도(예: 12MP)를 그대로 올리면 모바일 전용 표시 용도엔 과한 데다
            //    ImageKit 무료 플랜 스토리지/대역폭을 빠르게 잠식한다.
            //    실패 시 원본 data로 fallback해 업로드는 계속 진행.
            let payload = ImageDownsampler.normalizeForUpload(data) ?? data
            Log.trace(
                "프로필 이미지 정규화 — \(data.count) → \(payload.count) bytes",
                category: .network,
                level: .info
            )

            // 1) 서명 발급
            let auth: ImageKitAuthResponseDTO = try await networkService.request(
                endpoint: ImageKitAuthEndpoint.fetchAuthParams
            )

            // 2) multipart 본문 구성
            var builder = MultipartFormDataBuilder()
            let filename = "profile_\(Int(Date().timeIntervalSince1970)).jpg"
            builder.appendField(name: "publicKey", value: ImageKitConfig.publicKey)
            builder.appendField(name: "signature", value: auth.signature)
            builder.appendField(name: "token",     value: auth.token)
            builder.appendField(name: "expire",    value: String(auth.expire))
            builder.appendField(name: "fileName",  value: filename)
            builder.appendField(name: "folder",    value: ImageKitConfig.uploadFolder)
            builder.appendField(name: "useUniqueFileName", value: "true")
            builder.appendFile(name: "file", filename: filename, mimeType: "image/jpeg", data: payload)

            let boundary = builder.boundary
            let body = builder.finalize()

            Log.trace(
                "ImageKit 업로드 시작 — \(payload.count) bytes, boundary=\(boundary)",
                category: .network,
                level: .info
            )

            // 3) 업로드 (ImageKit 응답은 BaseResponseDTO 미적용이라 raw Data 경로)
            let raw = try await networkService.requestData(
                endpoint: ImageKitUploadEndpoint.upload(body: body, boundary: boundary)
            )
            let dto = try decoder.decode(ImageKitUploadResponseDTO.self, from: raw)

            Log.trace(
                "ImageKit 업로드 완료 — url=\(dto.url)",
                category: .network,
                level: .info
            )
            return dto.url

        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let domainError as DomainError {
            throw domainError
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
}
