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
        public init() {}
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
