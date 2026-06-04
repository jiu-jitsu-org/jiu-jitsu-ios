//
//  UploadedImage.swift
//  Domain
//
//  Created by suni on 6/4/26.
//

import Foundation

/// CDN(ImageKit) 업로드 직후의 원시 결과.
///
/// 우리 서버 등록(`POST /api/image`) 이전 단계의 산출물로, `cdnId`(ImageKit `fileId`)와
/// 호스팅 URL을 함께 담는다. 이후 `ImageRepository.registerImage(cdnId:imageUrl:)`에
/// 그대로 전달되어 서버 측 `RegisteredImage`(Int id 포함)로 승격된다.
public struct UploadedImage: Sendable, Equatable {
    /// CDN 식별자 (ImageKit `fileId`).
    public let cdnId: String
    /// 호스팅된 이미지 절대 URL.
    public let imageUrl: String

    public init(cdnId: String, imageUrl: String) {
        self.cdnId = cdnId
        self.imageUrl = imageUrl
    }
}
