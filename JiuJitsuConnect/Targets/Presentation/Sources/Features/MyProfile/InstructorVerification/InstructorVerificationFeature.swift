//
//  InstructorVerificationFeature.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import Foundation
import ComposableArchitecture
import CoreKit

/// 관장 사범 인증 바텀 시트 Feature.
/// MY 화면 우측 상단 "..." → "관장 사범 인증" 메뉴 진입 시 노출된다.
@Reducer
public struct InstructorVerificationFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 이미 제출된 인증 사진 URL. 존재하면(ownerRequested=true & 이미지 있음) 시트에
        /// 미리보기로 노출하고 CTA를 "재업로드"로 바꾼다. 미제출이면 `nil`.
        public let existingImageUrl: String?

        public init(existingImageUrl: String? = nil) {
            self.existingImageUrl = existingImageUrl
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case uploadTapped
            case cancelTapped
        }

        public enum DelegateAction: Sendable {
            case didSelectUpload
            case didCancel
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.uploadTapped):
                Log.trace("관장 사범 인증 - 사진 업로드 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectUpload))

            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case .delegate:
                return .none
            }
        }
    }
}
