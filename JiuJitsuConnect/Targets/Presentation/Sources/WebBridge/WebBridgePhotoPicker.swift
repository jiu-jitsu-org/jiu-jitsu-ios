//
//  WebBridgePhotoPicker.swift
//  Presentation
//
//  브릿지가 요청한 사진 선택(PICK_PHOTOS)을 PHPicker로 띄우고, 고른 사진을 웹에 보낼 형태
//  (JPEG · 긴 변 2400px 이내 · base64)로 바꾼다.
//
//  WHY 앱에서 줄이나: 원본(HEIC, 장당 수 MB)을 그대로 base64로 실으면 evaluateJavaScript를 지나는
//  문자열이 너무 커 느리다. 2400은 웹이 크롭으로 확대해도 업로드 기준(긴 변 1600)을 지키는 여유이고,
//  최종 압축은 웹이 한다(FE `native-dialog-bridge.md` 4-4절).
//

import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
import CoreKit

/// 여러 장 선택용 `PHPickerViewController` 래퍼.
///
/// PHPicker는 사용자가 고른 사진만 앱에 넘기므로 사진 권한이 '선택한 사진만'·거부여도 그대로 열린다.
/// 선택이 끝나면 `onFinishPicking`(시트 닫기)을 먼저 부르고, 변환이 끝난 뒤 `onPicked`로 결과를 넘긴다.
/// 변환 동안 시트를 붙잡아 두지 않기 위해서다.
struct WebBridgePhotoPicker: UIViewControllerRepresentable {
    let selectionLimit: Int
    let onFinishPicking: () -> Void
    let onPicked: ([PickedPhoto]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = selectionLimit
        // 웹에 고른 순서대로 넘기기로 했으므로, 선택 순번을 보여줘 사용자가 순서를 알 수 있게 한다.
        config.selection = .ordered
        // 변환은 앱이 하므로 원본 표현(HEIC 등)을 그대로 받는다(시스템의 사전 트랜스코딩 생략).
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinishPicking: onFinishPicking, onPicked: onPicked)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onFinishPicking: () -> Void
        let onPicked: ([PickedPhoto]) -> Void

        init(onFinishPicking: @escaping () -> Void, onPicked: @escaping ([PickedPhoto]) -> Void) {
            self.onFinishPicking = onFinishPicking
            self.onPicked = onPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onFinishPicking()
            // 취소도 didFinishPicking(빈 배열)으로 온다 → 빈 결과로 회신한다.
            guard !results.isEmpty else {
                onPicked([])
                return
            }
            let providers = PickedPhotoProviders(results.map(\.itemProvider))
            Task { [onPicked] in
                let photos = await PickedPhotoEncoder.encode(providers)
                onPicked(photos)
            }
        }
    }
}

/// `NSItemProvider`는 Sendable이 아니지만, 피커가 넘긴 뒤로는 인코더만 읽고 다른 곳에서 건드리지 않는다.
private struct PickedPhotoProviders: @unchecked Sendable {
    let items: [NSItemProvider]

    init(_ items: [NSItemProvider]) {
        self.items = items
    }
}

private enum PickedPhotoEncoder {
    /// 긴 변 상한. 웹이 크롭으로 확대해도 업로드 기준(긴 변 1600)을 지키는 여유.
    static let maxPixelSize = 2400
    /// 최종 압축은 웹이 하므로 여기서는 화질을 크게 깎지 않는다.
    static let jpegQuality = 0.9

    /// 고른 순서를 유지해 변환한다. 실패한 사진은 빼고 나머지만 보낸다.
    static func encode(_ providers: PickedPhotoProviders) async -> [PickedPhoto] {
        var photos: [PickedPhoto] = []
        for (index, provider) in providers.items.enumerated() {
            guard let jpeg = await loadDownsampledJPEG(from: provider) else { continue }
            let baseName = provider.suggestedName.flatMap { $0.isEmpty ? nil : $0 } ?? "photo-\(index + 1)"
            photos.append(
                PickedPhoto(
                    name: "\(baseName).jpg",
                    mimeType: "image/jpeg",
                    data: jpeg.base64EncodedString()
                )
            )
        }
        return photos
    }

    /// 파일 표현으로 받아 ImageIO로 바로 축소한다. UIImage로 원본 전체를 디코드하지 않아
    /// 4800만 화소 사진도 메모리를 크게 쓰지 않는다. 임시 파일은 콜백이 끝나면 지워지므로 콜백 안에서 처리한다.
    private static func loadDownsampledJPEG(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                guard let url else {
                    Log.trace("PICK_PHOTOS 사진 로드 실패: \(error.map { "\($0)" } ?? "-")", category: .system, level: .error)
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: downsampledJPEG(at: url))
            }
        }
    }

    private static func downsampledJPEG(at url: URL) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            Log.trace("PICK_PHOTOS 이미지 소스 생성 실패", category: .system, level: .error)
            return nil
        }
        // 썸네일 API는 원본보다 크게 늘리지 않으므로 2400보다 작은 사진은 원래 크기 그대로다.
        // WithTransform으로 EXIF 방향을 픽셀에 반영해, 방향 정보를 버리는 JPEG 재인코딩에도 회전이 맞는다.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            Log.trace("PICK_PHOTOS 이미지 축소 실패", category: .system, level: .error)
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            Log.trace("PICK_PHOTOS JPEG 인코딩 실패", category: .system, level: .error)
            return nil
        }
        return output as Data
    }
}
