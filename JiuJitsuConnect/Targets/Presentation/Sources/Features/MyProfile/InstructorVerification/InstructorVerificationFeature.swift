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

/// 운영팀 문의 메일. 인증 해제·변경처럼 관리자만 할 수 있는 일을 받는다.
/// 주소가 정해지기 전(`nil`)에는 문의 버튼을 숨겨 빈 링크가 나가지 않게 한다.
public enum SupportContact {
    public static let email: String? = nil
}

/// 관장 사범 인증 바텀 시트 Feature.
/// MY 화면 우측 상단 "..." → "관장 사범 인증" 메뉴 진입 시 노출된다.
@Reducer
public struct InstructorVerificationFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        public let verification: OwnerVerification
        /// 승인 화면에서 닉네임 옆 인증 표시를 그대로 보여 주는 데 쓴다.
        public let nickname: String
        /// 승인 화면의 '변경 문의' 받는 곳. 없으면 문의 버튼을 숨긴다.
        public let contactEmail: String?

        public init(
            verification: OwnerVerification = .notRequested,
            nickname: String = "",
            contactEmail: String? = SupportContact.email
        ) {
            self.verification = verification
            self.nickname = nickname
            self.contactEmail = contactEmail
        }

        /// 심사 중에 제출해 둔 인증 사진 URL. 있으면 시트에 미리보기로 노출하고 CTA를 "재업로드"로 바꾼다.
        /// 거절·승인된 서류는 다시 볼 이유가 없어 보이지 않는다.
        public var existingImageUrl: String? {
            verification.status == .pending ? verification.documentImageUrl : nil
        }

        public var isRejected: Bool {
            verification.status == .rejected
        }

        /// 이미 인증된 회원은 다시 올릴 서류가 없고 서버도 재신청을 막으므로, 업로드 대신 완료 상태만 보여 준다.
        public var isApproved: Bool {
            verification.status == .approved
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case uploadTapped
            case cancelTapped
            case contactTapped
        }

        public enum DelegateAction: Sendable {
            case didSelectUpload
            case didCancel
        }
    }

    @Dependency(\.openURL) var openURL

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.uploadTapped):
                Log.trace("관장 사범 인증 - 사진 업로드 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectUpload))

            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case .view(.contactTapped):
                // 인증 해제·변경은 관리자만 할 수 있어, 승인된 회원은 운영팀에 메일로 알린다.
                guard
                    let email = state.contactEmail,
                    let url = URL(string: "mailto:\(email)?subject=\("관장 사범 인증 정보 변경 문의".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
                else { return .none }
                return .run { _ in await openURL(url) }

            case .delegate:
                return .none
            }
        }
    }
}
