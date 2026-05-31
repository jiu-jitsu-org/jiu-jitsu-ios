//
//  ImageUploadRepository.swift
//  Domain
//
//  Created by suni on 5/25/26.
//

import Foundation

/// 이미지 호스팅 업로드 추상화.
///
/// 도메인 계층은 "바이트와 사용처를 넘기면 호스팅된 URL을 받는다" 까지만 안다.
/// ImageKit / S3 / Firebase Storage 등 어떤 구현이든 동일 인터페이스로 갈아끼울 수 있다.
public protocol ImageUploadRepository: Sendable {
    /// 이미지를 호스팅에 업로드하고 절대 URL 문자열을 반환한다.
    /// - Parameters:
    ///   - data: 업로드할 이미지 바이트 (JPEG 권장)
    ///   - purpose: 사용 맥락 — 구현체가 폴더/파일명 prefix 결정에 사용한다
    /// - Returns: 호스팅된 이미지의 절대 URL 문자열 (https)
    /// - Throws: `DomainError`
    func uploadImage(_ data: Data, purpose: ImageUploadPurpose) async throws -> String
}
