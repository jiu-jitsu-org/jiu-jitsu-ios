//
//  PhotoLibraryPickerView.swift
//  Presentation
//
//  Created by suni on 5/20/26.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreKit

/// 시스템 사진 라이브러리(`PHPickerViewController`)를 띄우는 SwiftUI 래퍼.
///
/// 1매 선택 후 호출자에 `UIImage`를 전달한다. `PHPickerViewController`는 사용자가
/// 명시적으로 선택한 사진만 앱에 전달되므로 별도 권한 요청이 필요 없다.
struct PhotoLibraryPickerView: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: (UIImage) -> Void
        let onCancel: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }

            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else {
                Log.trace("PHPicker: 선택한 항목을 UIImage로 로드할 수 없음", category: .system, level: .error)
                onCancel()
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [onPicked, onCancel] object, error in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        onPicked(image)
                    } else {
                        if let error {
                            Log.trace("PHPicker 이미지 로드 실패: \(error)", category: .system, level: .error)
                        }
                        onCancel()
                    }
                }
            }
        }
    }
}
