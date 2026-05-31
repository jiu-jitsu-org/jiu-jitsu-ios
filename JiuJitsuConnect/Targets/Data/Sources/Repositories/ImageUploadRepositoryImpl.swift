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
/// 흐름 (모든 purpose 공통):
/// 1. 우리 BE의 `/api/imagekit/auth`로부터 `token`/`expire`/`signature` 발급
/// 2. multipart 본문 구성 (폴더/파일명 prefix는 purpose에서 도출)
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

    public func uploadImage(_ data: Data, purpose: ImageUploadPurpose) async throws -> String {
        do {
            // 0) 업로드 페이로드 정규화 — purpose별 maxPixel/quality 적용.
            //    프로필은 헤더 표시 전용이라 공격적으로 줄이고, 인증 사진은 관리자 검수에서
            //    텍스트/디테일 가독성이 중요하므로 보수적으로 압축한다.
            //    실패 시 원본 data로 fallback해 업로드는 계속 진행.
            let compression = ImageKitConfig.uploadCompression(for: purpose)
            let payload = ImageDownsampler.normalizeForUpload(
                data,
                maxPixel: compression.maxPixel,
                quality: compression.quality
            ) ?? data
            Log.trace(
                "이미지 정규화 (\(purpose.logLabel), \(Int(compression.maxPixel))px / q\(compression.quality)) — \(data.count) → \(payload.count) bytes",
                category: .network,
                level: .info
            )

            // 1) 서명 발급
            let auth: ImageKitAuthResponseDTO = try await networkService.request(
                endpoint: ImageKitAuthEndpoint.fetchAuthParams
            )

            // 2) multipart 본문 구성 — folder/prefix는 purpose-aware
            var builder = MultipartFormDataBuilder()
            let prefix = ImageKitConfig.filenamePrefix(for: purpose)
            let folder = ImageKitConfig.uploadFolder(for: purpose)
            let filename = "\(prefix)_\(Int(Date().timeIntervalSince1970)).jpg"
            builder.appendField(name: "publicKey", value: ImageKitConfig.publicKey)
            builder.appendField(name: "signature", value: auth.signature)
            builder.appendField(name: "token",     value: auth.token)
            builder.appendField(name: "expire",    value: String(auth.expire))
            builder.appendField(name: "fileName",  value: filename)
            builder.appendField(name: "folder",    value: folder)
            builder.appendField(name: "useUniqueFileName", value: "true")
            builder.appendFile(name: "file", filename: filename, mimeType: "image/jpeg", data: payload)

            let boundary = builder.boundary
            let body = builder.finalize()

            Log.trace(
                "ImageKit 업로드 시작 (\(purpose.logLabel)) — \(payload.count) bytes, folder=\(folder), boundary=\(boundary)",
                category: .network,
                level: .info
            )

            // 3) 업로드 (ImageKit 응답은 BaseResponseDTO 미적용이라 raw Data 경로)
            let raw = try await networkService.requestData(
                endpoint: ImageKitUploadEndpoint.upload(body: body, boundary: boundary)
            )
            let dto = try decoder.decode(ImageKitUploadResponseDTO.self, from: raw)

            Log.trace(
                "ImageKit 업로드 완료 (\(purpose.logLabel)) — url=\(dto.url)",
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

// MARK: - Log label (Data 내부 디버깅용 — Presentation의 표시 텍스트와 분리)

private extension ImageUploadPurpose {
    var logLabel: String {
        switch self {
        case .profileImage:           return "프로필 이미지"
        case .instructorVerification: return "관장 사범 인증"
        }
    }
}
