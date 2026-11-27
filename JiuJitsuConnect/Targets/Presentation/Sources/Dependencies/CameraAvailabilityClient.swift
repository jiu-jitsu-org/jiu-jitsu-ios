//
//  CameraAvailabilityClient.swift
//  Presentation
//
//  이 기기에서 카메라 촬영을 쓸 수 있는지(#353).
//  카메라가 없는 환경(Apple 실리콘 Mac에서 iPhone 앱 실행 등)에서 `.camera` picker를 띄우면 앱이 죽을 수 있다.
//  카메라 접근을 거부한 사람에게는 picker 대신 설정으로 가는 길을 보여 준다(QA A3-8).
//

import AVFoundation
import ComposableArchitecture
import UIKit

public struct CameraAvailabilityClient: Sendable {
    public var isAvailable: @Sendable @MainActor () -> Bool
    /// 카메라 접근을 거부했거나(설정에서 끔) 기기 관리로 막혀 있는지. 아직 묻지 않았으면 false — picker가 권한 창을 띄운다.
    public var isAccessDenied: @Sendable () -> Bool

    public init(
        isAvailable: @Sendable @MainActor @escaping () -> Bool,
        isAccessDenied: @Sendable @escaping () -> Bool = { false }
    ) {
        self.isAvailable = isAvailable
        self.isAccessDenied = isAccessDenied
    }
}

extension CameraAvailabilityClient: DependencyKey {
    public static let liveValue = CameraAvailabilityClient(
        isAvailable: { UIImagePickerController.isSourceTypeAvailable(.camera) },
        isAccessDenied: {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted: true
            case .authorized, .notDetermined: false
            @unknown default: false
            }
        }
    )

    public static let testValue = CameraAvailabilityClient(
        isAvailable: unimplemented("CameraAvailabilityClient.isAvailable", placeholder: true),
        isAccessDenied: unimplemented("CameraAvailabilityClient.isAccessDenied", placeholder: false)
    )

    public static let previewValue = CameraAvailabilityClient(
        isAvailable: { true },
        isAccessDenied: { false }
    )
}

extension DependencyValues {
    public var cameraAvailabilityClient: CameraAvailabilityClient {
        get { self[CameraAvailabilityClient.self] }
        set { self[CameraAvailabilityClient.self] = newValue }
    }
}
