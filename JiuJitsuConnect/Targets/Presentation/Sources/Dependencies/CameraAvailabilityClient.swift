//
//  CameraAvailabilityClient.swift
//  Presentation
//
//  이 기기에서 카메라 촬영을 쓸 수 있는지(#353).
//  카메라가 없는 환경(Apple 실리콘 Mac에서 iPhone 앱 실행 등)에서 `.camera` picker를 띄우면 앱이 죽을 수 있다.
//

import ComposableArchitecture
import UIKit

public struct CameraAvailabilityClient: Sendable {
    public var isAvailable: @Sendable @MainActor () -> Bool

    public init(isAvailable: @Sendable @MainActor @escaping () -> Bool) {
        self.isAvailable = isAvailable
    }
}

extension CameraAvailabilityClient: DependencyKey {
    public static let liveValue = CameraAvailabilityClient(
        isAvailable: { UIImagePickerController.isSourceTypeAvailable(.camera) }
    )

    public static let testValue = CameraAvailabilityClient(
        isAvailable: unimplemented("CameraAvailabilityClient.isAvailable", placeholder: true)
    )

    public static let previewValue = CameraAvailabilityClient(
        isAvailable: { true }
    )
}

extension DependencyValues {
    public var cameraAvailabilityClient: CameraAvailabilityClient {
        get { self[CameraAvailabilityClient.self] }
        set { self[CameraAvailabilityClient.self] = newValue }
    }
}
