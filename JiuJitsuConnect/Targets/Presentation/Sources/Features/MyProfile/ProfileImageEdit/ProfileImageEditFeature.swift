//
//  ProfileImageEditFeature.swift
//  Presentation
//
//  Created by suni on 5/19/26.
//

import Foundation
import ComposableArchitecture
import CoreKit

@Reducer
public struct ProfileImageEditFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 삭제 옵션 노출 여부 (현재 프로필 이미지가 있을 때만 표시)
        var canDelete: Bool

        public init(canDelete: Bool = false) {
            self.canDelete = canDelete
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case cameraTapped
            case albumTapped
            case deleteTapped
            case cancelTapped
        }

        public enum DelegateAction: Sendable {
            case didSelectCamera
            case didSelectAlbum
            case didSelectDelete
            case didCancel
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.cameraTapped):
                Log.trace("프로필 이미지 수정 - 사진 촬영 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectCamera))

            case .view(.albumTapped):
                Log.trace("프로필 이미지 수정 - 앨범에서 찾기 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectAlbum))

            case .view(.deleteTapped):
                Log.trace("프로필 이미지 수정 - 삭제 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectDelete))

            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case .delegate:
                return .none
            }
        }
    }
}
