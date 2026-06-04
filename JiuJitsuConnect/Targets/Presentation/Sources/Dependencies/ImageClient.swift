//
//  ImageClient.swift
//  Presentation
//
//  Created by suni on 6/4/26.
//

import ComposableArchitecture
import Foundation
import Domain

/// 서버 측 이미지 레코드 관리를 위한 TCA 의존성.
///
/// CDN(ImageKit) 업로드 자체는 `ImageUploadClient`가 담당하고, 본 클라이언트는 그 결과
/// (`cdnId`/`imageUrl`)를 BE에 등록·삭제한다. 실제 구현체는 `Data` 계층의
/// `ImageRepositoryImpl`이 `DependencyContainer.configureImageClient()`를 통해 주입된다.
public struct ImageClient: Sendable {
    /// CDN 업로드된 이미지를 서버에 등록한다 (POST `/api/image`). 등록된 이미지 정보를 반환한다.
    public var registerImage: @Sendable (_ cdnId: String, _ imageUrl: String) async throws -> RegisteredImage
    /// 등록된 이미지를 삭제한다 (DELETE `/api/image/{id}`).
    public var deleteImage: @Sendable (_ id: Int64) async throws -> Void

    public init(
        registerImage: @Sendable @escaping (String, String) async throws -> RegisteredImage,
        deleteImage: @Sendable @escaping (Int64) async throws -> Void
    ) {
        self.registerImage = registerImage
        self.deleteImage = deleteImage
    }
}

// MARK: - DependencyKey

extension ImageClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: ImageClient = ImageClient(
        registerImage: { cdnId, imageUrl in
            RegisteredImage(id: 1, cdnId: cdnId, imageUrl: imageUrl, status: .temp)
        },
        deleteImage: { _ in }
    )

    public static let previewValue: ImageClient = ImageClient(
        registerImage: { cdnId, imageUrl in
            RegisteredImage(id: 1, cdnId: cdnId, imageUrl: imageUrl, status: .temp)
        },
        deleteImage: { _ in }
    )
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}

extension ImageClient {
    static let unimplemented: Self = Self(
        registerImage: { _, _ in
            fatalError("ImageClient.registerImage is not implemented")
        },
        deleteImage: { _ in
            fatalError("ImageClient.deleteImage is not implemented")
        }
    )
}
