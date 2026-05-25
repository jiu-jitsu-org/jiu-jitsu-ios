//
//  ProfileImageCropFeature.swift
//  Presentation
//
//  Created by suni on 5/20/26.
//

import Foundation
import UIKit
import ComposableArchitecture
import CoreKit

@Reducer
public struct ProfileImageCropFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 크롭 대상 원본 이미지의 직렬화된 Data
        ///
        /// `UIImage`는 Equatable·Sendable이 까다로워 Data로 직렬화해 상태에 보관한다.
        /// 한 세션 동안 동일 인스턴스가 유지되므로 큰 비교 비용은 발생하지 않는다.
        /// 뷰에서는 매 렌더링 시점에 `UIImage(data:)`로 복원해 사용.
        public let originalImageData: Data

        public init(originalImageData: Data) {
            self.originalImageData = originalImageData
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case cancelTapped
            case confirmTapped(croppedImageData: Data)
        }

        public enum DelegateAction: Sendable {
            case didCancel
            case didConfirm(croppedImageData: Data)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case let .view(.confirmTapped(data)):
                Log.trace("프로필 이미지 크롭 완료 (\(data.count) bytes)", category: .debug, level: .info)
                return .send(.delegate(.didConfirm(croppedImageData: data)))

            case .delegate:
                return .none
            }
        }
    }
}
