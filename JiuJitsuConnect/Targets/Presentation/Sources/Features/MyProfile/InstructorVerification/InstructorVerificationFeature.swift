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
/// 이용약관·개인정보처리방침의 운영자 메일과 같은 주소다. `nil`이면 문의 버튼을 숨긴다.
public enum SupportContact {
    public static let email: String? = "jiujitsulab.team@gmail.com"
}

/// 관장 사범 인증 바텀 시트 Feature.
/// MY 화면 우측 상단 "..." → "관장 사범 인증" 메뉴 진입 시 노출된다.
@Reducer
public struct InstructorVerificationFeature: Sendable {
    public init() {}

    private enum CancelID { case contact }

    @ObservableState
    public struct State: Equatable, Sendable {
        public let verification: OwnerVerification
        public let nickname: String
        /// 승인 화면의 '변경 문의' 받는 곳. 없으면 문의 버튼을 숨긴다.
        public let contactEmail: String?
        /// 앨범 · 카메라에서 막 고른, 아직 올리지 않은 사진. 있으면 미리보기로 보여 주고 [이 사진으로 신청]을 받는다(#388).
        public let pickedImageData: Data?

        public init(
            verification: OwnerVerification = .notRequested,
            nickname: String = "",
            contactEmail: String? = SupportContact.email,
            pickedImageData: Data? = nil
        ) {
            self.verification = verification
            self.nickname = nickname
            self.contactEmail = contactEmail
            self.pickedImageData = pickedImageData
        }

        /// 시트가 보여 줄 단계. 고른 사진이 있으면 서버 상태(처음 · 심사 중 · 반려)보다 확인 단계가 먼저다.
        /// 이미 인증된 회원은 다시 올릴 서류가 없고 서버도 재신청을 막으므로, 업로드 대신 완료 상태만 보여 준다.
        public var phase: Phase {
            if verification.status == .approved { return .approved }
            if let pickedImageData { return .picked(pickedImageData) }
            switch verification.status {
            case .pending: return .pending
            case .rejected: return .rejected
            case .notRequested, .approved: return .notRequested
            }
        }

        /// 심사 중에 제출해 둔 인증 사진 URL. 있으면 시트에 썸네일로 보여 준다.
        /// 거절·승인된 서류는 다시 볼 이유가 없어 보이지 않는다.
        public var existingImageUrl: String? {
            phase == .pending ? verification.documentImageUrl : nil
        }
    }

    public enum Phase: Equatable, Sendable {
        case notRequested
        /// 사진을 골랐고 아직 신청하지 않음
        case picked(Data)
        case pending
        case rejected
        case approved
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case uploadTapped
            /// 고른 사진 확인 단계의 [이 사진으로 신청]
            case submitTapped
            /// 고른 사진 확인 단계의 [다시 고르기]
            case repickTapped
            case cancelTapped
            case contactTapped
        }

        public enum DelegateAction: Sendable {
            case didSelectUpload
            /// 고른 사진으로 신청. 부모가 시트를 닫고 업로드 → 인증 요청을 이어 간다.
            case didConfirmImage(Data)
            case didCancel
            /// 문의 메일 앱이 열림. 루트의 분석 기록만 본다(#430).
            case contactOpened
            /// 메일 앱을 열지 못함(메일 앱 삭제 등). 부모가 주소를 복사하고 알려 준다.
            case mailUnavailable(email: String)
        }
    }

    @Dependency(\.openURL) var openURL

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.uploadTapped):
                Log.trace("관장 사범 인증 - 사진 업로드 선택", category: .debug, level: .info)
                return .send(.delegate(.didSelectUpload))

            case .view(.submitTapped):
                guard let data = state.pickedImageData else { return .none }
                Log.trace("관장 사범 인증 - 고른 사진으로 신청", category: .debug, level: .info)
                return .send(.delegate(.didConfirmImage(data)))

            case .view(.repickTapped):
                // 고르기 시트(앨범 · 카메라)로 돌아간다. 고른 사진은 버린다.
                Log.trace("관장 사범 인증 - 사진 다시 고르기", category: .debug, level: .info)
                return .send(.delegate(.didSelectUpload))

            case .view(.cancelTapped):
                return .send(.delegate(.didCancel))

            case .view(.contactTapped):
                // 인증 해제·변경은 관리자만 할 수 있어, 승인된 회원은 운영팀에 메일로 알린다.
                guard let email = state.contactEmail else { return .none }
                var components = URLComponents()
                components.scheme = "mailto"
                components.path = email
                components.queryItems = [URLQueryItem(name: "subject", value: "관장 사범 인증 정보 변경 문의")]
                guard let url = components.url else {
                    Log.trace("관장 사범 인증 문의 메일 주소를 만들지 못함: \(email)", category: .view, level: .error)
                    return .none
                }
                return .run { send in
                    if await openURL(url) {
                        await send(.delegate(.contactOpened))
                    } else {
                        Log.trace("관장 사범 인증 문의 메일을 열지 못함(메일 앱 없음 등)", category: .view, level: .error)
                        await send(.delegate(.mailUnavailable(email: email)))
                    }
                }
                // 빠르게 두 번 누르면 앞 시도를 취소해, 메일 앱이 없을 때 알림이 두 번 오지 않게 한다.
                .cancellable(id: CancelID.contact, cancelInFlight: true)

            case .delegate:
                return .none
            }
        }
    }
}
