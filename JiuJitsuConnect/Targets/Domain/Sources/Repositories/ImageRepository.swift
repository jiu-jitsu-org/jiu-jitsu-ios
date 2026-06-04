//
//  ImageRepository.swift
//  Domain
//
//  Created by suni on 6/4/26.
//

import Foundation

/// 서버 측 이미지 레코드 관리 추상화.
///
/// CDN(ImageKit) 업로드 자체는 `ImageUploadRepository`가 담당하고,
/// 본 프로토콜은 업로드 결과(`cdnId`/`imageUrl`)를 BE에 등록·삭제하는 책임을 가진다.
public protocol ImageRepository: Sendable {
    /// CDN 업로드된 이미지를 서버에 등록한다 (POST `/api/image`).
    ///
    /// TEMP 상태로 저장되며, 게시물/프로필 저장 시 ACTIVE로 전환된다.
    /// - Parameters:
    ///   - cdnId: CDN 식별자
    ///   - imageUrl: 호스팅된 이미지 절대 URL
    /// - Returns: 등록된 이미지 정보 (`id` 포함)
    /// - Throws: `DomainError`
    func registerImage(cdnId: String, imageUrl: String) async throws -> RegisteredImage

    /// 등록된 이미지를 삭제한다 (DELETE `/api/image/{id}`).
    ///
    /// `cdnId`가 있는 경우 CDN에서도 함께 삭제된다.
    /// - Parameter id: 이미지 파일 ID
    /// - Throws: `DomainError`
    func deleteImage(id: Int64) async throws
}
