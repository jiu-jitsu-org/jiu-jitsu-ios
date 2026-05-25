//
//  ImageUploadRepository.swift
//  Domain
//
//  Created by suni on 5/25/26.
//

import Foundation

/// 이미지 호스팅 업로드 추상화.
///
/// 도메인 계층은 "바이트를 보내면 호스팅된 URL을 받는다" 까지만 안다.
/// ImageKit / S3 / Firebase Storage 등 어떤 구현이든 동일 인터페이스로 갈아끼울 수 있다.
public protocol ImageUploadRepository: Sendable {
    /// 프로필 이미지를 업로드하고 호스팅된 URL 문자열을 반환한다.
    /// - Parameter data: 업로드할 이미지 바이트 (JPEG 권장)
    /// - Returns: 호스팅된 이미지의 절대 URL 문자열 (https)
    /// - Throws: `DomainError`
    func uploadProfileImage(_ data: Data) async throws -> String
}
