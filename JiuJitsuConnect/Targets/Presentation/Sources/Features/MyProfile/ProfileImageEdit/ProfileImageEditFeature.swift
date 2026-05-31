//
//  ProfileImageEditFeature.swift
//  Presentation
//
//  Created by suni on 5/19/26.
//

import Foundation
import ComposableArchitecture
import CoreKit

/// 사진 촬영 / 앨범에서 찾기 / (선택)삭제 옵션을 제공하는 액션 시트 Feature.
///
/// 같은 UI를 두 곳에서 사용한다:
/// - `.profileImage`: MY 헤더의 프로필 이미지 수정 진입 (기본값, 삭제 가능)
/// - `.instructorVerification`: 관장 사범 인증 사진 첨부 진입 (삭제 불가)
///
/// 다운스트림(업로드 API/타겟 엔드포인트)은 부모 Feature(MyProfileFeature)가
/// `Purpose` 또는 자체 트래킹 상태(`pendingImagePurpose`)로 분기한다.
@Reducer
public struct ProfileImageEditFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 시트의 사용 맥락 — 타이틀/로그 분기에 사용
        var purpose: Purpose

        /// 삭제 옵션 노출 여부 (프로필 이미지 수정 흐름에서 이미지가 있을 때만 true)
        var canDelete: Bool

        var title: String { purpose.title }

        public init(purpose: Purpose = .profileImage, canDelete: Bool = false) {
            self.purpose = purpose
            self.canDelete = canDelete
        }
    }

    public enum Purpose: Equatable, Sendable {
        case profileImage
        case instructorVerification

        var title: String {
            switch self {
            case .profileImage: "프로필 이미지 수정"
            case .instructorVerification: "사진 첨부"
            }
        }

        /// 로그 prefix — 어느 흐름에서 발생한 액션인지 식별하기 위함
        fileprivate var logPrefix: String {
            switch self {
            case .profileImage: "프로필 이미지 수정"
            case .instructorVerification: "관장 사범 인증 - 사진 첨부"
            }
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
        Reduce { state, action in
            switch action {
            case .view(.cameraTapped):
                Log.trace("\(state.purpose.logPrefix) - 사진 촬영 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectCamera))

            case .view(.albumTapped):
                Log.trace("\(state.purpose.logPrefix) - 앨범에서 찾기 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectAlbum))

            case .view(.deleteTapped):
                Log.trace("\(state.purpose.logPrefix) - 삭제 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectDelete))

            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case .delegate:
                return .none
            }
        }
    }
}
