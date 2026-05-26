//
//  TermsAgreementFeature.swift
//  Presentation
//
//  Created by suni on 10/3/25.
//

import Foundation
import ComposableArchitecture
import DesignSystem
import Domain
import CoreKit

@Reducer
public struct TermsAgreementFeature: Sendable {
    public init() {}

    // MARK: - URL 헬퍼 (SettingsFeature.TermsURL과 동일 패턴)
    private enum TermsURL {
        static let serviceTerms     = makeURL(path: "/policies/terms-of-service")
        static let privacyPolicy    = makeURL(path: "/policies/privacy-policy")
        static let marketingConsent = makeURL(path: "/policies/marketing-consent")

        private static func makeURL(path: String) -> URL? {
            guard
                let baseString = Bundle.main.object(forInfoDictionaryKey: "WEB_URL") as? String,
                !baseString.isEmpty,
                let base = URL(string: baseString)
            else {
                Log.trace("WEB_URL is not set in Info.plist", category: .system, level: .error)
                return nil
            }
            return base.appendingPathComponent(path)
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        var rows: IdentifiedArrayOf<TermsAgreementRowFeature.State>

        @Presents var termsWebCover: TermsWebViewFeature.State?

        // Derived State
        var buttonTitle: String {
            didAgreeToAllRequired ? "다음" : "모두 동의하기"
        }

        var didAgreeToAllRequired: Bool {
            rows.filter { $0.term.type == .required }
                .allSatisfy { $0.isChecked }
        }

        var isMarketingAgreed: Bool {
            rows.first { $0.term.type == .optional }?.isChecked ?? false
        }

        private static let fixedTerms: [TermItem] = [
            .init(title: "서비스 이용약관 동의",   type: .required, contentURL: TermsURL.serviceTerms),
            .init(title: "개인정보 처리방침 동의",  type: .required, contentURL: TermsURL.privacyPolicy),
            .init(title: "만 14세 이상입니다.",     type: .required),
            .init(title: "마케팅 정보 수신",         type: .optional, contentURL: TermsURL.marketingConsent)
        ]

        public init() {
            self.rows = .init(
                uniqueElements: Self.fixedTerms.map { TermsAgreementRowFeature.State(term: $0) }
            )
        }
    }

    public enum Action: Sendable {
        case rows(IdentifiedAction<TermsAgreementRowFeature.State.ID, TermsAgreementRowFeature.Action>)
        case view(ViewAction)
        case delegate(DelegateAction)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)

        public enum ViewAction: Sendable {
            case mainButtonTapped
        }

        public enum DelegateAction: Sendable {
            case didFinishAgreement(isMarketingAgreed: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.mainButtonTapped):
                if state.didAgreeToAllRequired {
                    Log.trace("필수 약관 동의 완료 -> 다음 화면 이동", category: .view, level: .debug)
                    return .send(.delegate(.didFinishAgreement(isMarketingAgreed: state.isMarketingAgreed)))

                } else {
                    Log.trace("모두 동의하기 실행", category: .view, level: .debug)
                    state.rows.ids.forEach { id in
                        state.rows[id: id]?.isChecked = true
                    }

                    // [정책 확인 필요] '모두 동의' 버튼 클릭 시 바로 다음 화면으로 넘어가는 것이 기획 의도라면 아래 코드 유지.
                    // 만약 체크만 하고 유저가 다시 '다음'을 눌러야 한다면 return .none으로 변경해야 함.
                    return .send(.delegate(.didFinishAgreement(isMarketingAgreed: true)))
                }

            case .rows(.element(id: let id, action: .seeDetailsTapped)):
                guard let row = state.rows[id: id], let url = row.term.contentURL else {
                    return .none
                }
                // 외부 브라우저 대신 인앱 웹뷰로 열기
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .termsWebCover(.presented(.delegate(.didClose))):
                state.termsWebCover = nil
                return .none

            case .rows, .delegate, .termsWebCover:
                return .none
            }
        }
        .forEach(\.rows, action: \.rows) {
            TermsAgreementRowFeature()
        }
        .ifLet(\.$termsWebCover, action: \.termsWebCover) {
            TermsWebViewFeature()
        }
    }
}
