//
//  ImageUploadClient.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import ComposableArchitecture
import Foundation
import Domain

/// 이미지 호스팅 업로드를 위한 TCA 의존성.
///
/// `purpose`로 사용 맥락(프로필 / 관장 사범 인증 / 추후 채팅·커뮤니티 첨부 등)을 구분하며,
/// 호스팅 폴더와 파일명 prefix는 Data 레이어에서 도출된다. 실제 구현체는 `Data` 계층의
/// `ImageUploadRepositoryImpl`(CDN 업로드) + `ImageRepositoryImpl`(서버 등록)을 묶어
/// `DependencyContainer.configureImageUploadClient()`를 통해 주입된다.
public struct ImageUploadClient: Sendable {
    /// 이미지를 CDN에 업로드(1·2단계)하고 우리 서버에 등록(3단계, `POST /api/image`)한 뒤,
    /// 발급된 `id`를 포함한 `RegisteredImage`를 반환한다. 호출부는 이 `id`를 최종 API
    /// (프로필 설정 / 관장사범 인증)에 전달한다.
    public var uploadImage: @Sendable (Data, ImageUploadPurpose) async throws -> RegisteredImage

    public init(
        uploadImage: @Sendable @escaping (Data, ImageUploadPurpose) async throws -> RegisteredImage
    ) {
        self.uploadImage = uploadImage
    }
}

// MARK: - DependencyKey

extension ImageUploadClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: ImageUploadClient = ImageUploadClient(
        uploadImage: { _, purpose in
            switch purpose {
            case .profileImage:
                RegisteredImage(id: 1, cdnId: "test_cdn", imageUrl: "https://ik.imagekit.io/test/profile_test.jpg", status: .temp)
            case .instructorVerification:
                RegisteredImage(id: 2, cdnId: "test_cdn", imageUrl: "https://ik.imagekit.io/test/verification_test.jpg", status: .temp)
            }
        }
    )

    public static let previewValue: ImageUploadClient = ImageUploadClient(
        uploadImage: { _, purpose in
            switch purpose {
            case .profileImage:
                RegisteredImage(id: 1, cdnId: "preview_cdn", imageUrl: "https://ik.imagekit.io/preview/profile_preview.jpg", status: .temp)
            case .instructorVerification:
                RegisteredImage(id: 2, cdnId: "preview_cdn", imageUrl: "https://ik.imagekit.io/preview/verification_preview.jpg", status: .temp)
            }
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
        uploadImage: { _, _ in
            fatalError("ImageUploadClient.uploadImage is not implemented")
        }
    )
}
