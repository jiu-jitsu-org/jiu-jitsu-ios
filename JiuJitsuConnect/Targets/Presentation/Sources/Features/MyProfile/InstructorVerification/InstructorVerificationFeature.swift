//
//  InstructorVerificationFeature.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import Foundation
import ComposableArchitecture
import CoreKit
import Domain

/// 관장 사범 인증 바텀 시트 Feature.
/// MY 화면 우측 상단 "..." → "관장 사범 인증" 메뉴 진입 시 노출된다.
@Reducer
public struct InstructorVerificationFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        public let verification: OwnerVerification

        public init(verification: OwnerVerification = .notRequested) {
            self.verification = verification
        }

        /// 심사 중에 제출해 둔 인증 사진 URL. 있으면 시트에 미리보기로 노출하고 CTA를 "재업로드"로 바꾼다.
        /// 거절·승인된 서류는 다시 볼 이유가 없어 보이지 않는다.
        public var existingImageUrl: String? {
            verification.status == .pending ? verification.documentImageUrl : nil
        }

        public var isRejected: Bool {
            verification.status == .rejected
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
