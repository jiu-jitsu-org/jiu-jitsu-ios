//
//  ImageUploadClient.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import ComposableArchitecture
import Foundation

/// 이미지 호스팅 업로드를 위한 TCA 의존성.
///
/// 현재는 프로필 이미지만 다루지만, 추후 채팅/커뮤니티 첨부 등에서 재사용할 수 있도록
/// 별도 클라이언트로 분리한다. 실제 구현체는 `Data` 계층의 `ImageUploadRepositoryImpl`이
/// `DependencyContainer.configureImageUploadClient()`를 통해 주입된다.
public struct ImageUploadClient: Sendable {
    /// 프로필 이미지를 업로드하고 호스팅된 URL을 반환한다.
    public var uploadProfileImage: @Sendable (Data) async throws -> String

    public init(
        uploadProfileImage: @Sendable @escaping (Data) async throws -> String
    ) {
        self.uploadProfileImage = uploadProfileImage
    }
}

// MARK: - DependencyKey

extension ImageUploadClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: ImageUploadClient = ImageUploadClient(
        uploadProfileImage: { _ in
            "https://ik.imagekit.io/test/profile_test.jpg"
        }
    )

    public static let previewValue: ImageUploadClient = ImageUploadClient(
        uploadProfileImage: { _ in
            "https://ik.imagekit.io/preview/profile_preview.jpg"
        }
    )
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var imageUploadClient: ImageUploadClient {
        get { self[ImageUploadClient.self] }
        set { self[ImageUploadClient.self] = newValue }
    }
}

extension ImageUploadClient {
    static let unimplemented: Self = Self(
        uploadProfileImage: { _ in
            fatalError("ImageUploadClient.uploadProfileImage is not implemented")
        }
    )
}
