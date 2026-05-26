//
//  ImageDownsampler.swift
//  Data
//
//  Created by suni on 5/26/26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreKit

/// 업로드 페이로드 정규화 유틸.
///
/// `UIGraphicsImageRenderer`는 원본 UIImage 전체를 디코드해 메모리에 올리므로
/// 12MP+ 사진에서 스파이크가 큰 반면, ImageIO의 `CGImageSourceCreateThumbnailAtIndex`는
/// 썸네일 단계에서만 픽셀을 풀어 메모리 효율이 좋다.
///
/// 사용처: ImageKit 업로드 직전 `ImageUploadRepositoryImpl`.
enum ImageDownsampler {

    /// ImageKit 업로드 기본값 — 모바일 전용 프로필 표시 기준.
    /// - maxPixel 1024: 3x retina에서 풀스크린 표시(약 414pt) 대비 2배 여유.
    /// - quality 0.8: 시각 차이 거의 없이 0.9 대비 ~35% 용량 감소.
    static let defaultMaxPixel: CGFloat = 1024
    static let defaultQuality: CGFloat = 0.8

    /// 긴 변을 `maxPixel`로 다운샘플 후 JPEG로 재인코딩한다.
    ///
    /// 실패 시 nil 반환 — 호출부에서 원본 data로 fallback할지 결정한다.
    static func normalizeForUpload(
        _ data: Data,
        maxPixel: CGFloat = defaultMaxPixel,
        quality: CGFloat = defaultQuality
    ) -> Data? {
        let srcOptions: CFDictionary = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(data as CFData, srcOptions) else {
            Log.trace("ImageDownsampler: CGImageSource 생성 실패", category: .system, level: .error)
            return nil
        }

        let thumbnailOptions: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // EXIF orientation을 픽셀에 적용 — 회전된 사진을 정방향으로 정규화
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            Log.trace("ImageDownsampler: 썸네일 생성 실패", category: .system, level: .error)
            return nil
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            Log.trace("ImageDownsampler: CGImageDestination 생성 실패", category: .system, level: .error)
            return nil
        }

        let destinationOptions: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary

        CGImageDestinationAddImage(destination, thumbnail, destinationOptions)

        guard CGImageDestinationFinalize(destination) else {
            Log.trace("ImageDownsampler: JPEG finalize 실패", category: .system, level: .error)
            return nil
        }

        return outputData as Data
    }
}
