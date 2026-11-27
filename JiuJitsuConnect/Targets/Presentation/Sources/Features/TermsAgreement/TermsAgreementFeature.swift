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
        /// 이 기기에서 최근 로그인한 수단이 지금 가입하려는 수단과 다를 때 그 수단(#380). 안내 문구가 이 수단을 짚는다.
        var recentOtherProvider: SNSProvider?

        @Presents var termsWebCover: TermsWebViewFeature.State?

        // Derived State
        var buttonTitle: String {
            if didAgreeToAllRequired { return "다음" }
            return fillsRequiredOnly ? "필수 항목 동의하기" : "모두 동의하기"
        }

        /// 이미 하나라도 직접 체크했으면 버튼은 남은 필수 항목만 채운다(QA A5-3).
        /// 항목을 골라 체크하던 사람이 '모두 동의하기'를 눌러 일부러 비워 둔 선택 항목(광고성 정보 수신)까지 켜지지 않게 한다.
        /// 아무것도 체크하지 않았을 때만 선택 항목까지 한 번에 켜는 '모두 동의하기'다 — 켠 뒤에도 화면에 머물러 선택 항목을 끌 수 있다.
        var fillsRequiredOnly: Bool {
            rows.contains { $0.isChecked }
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

        public init(recentOtherProvider: SNSProvider? = nil) {
            self.recentOtherProvider = recentOtherProvider
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
                    // 정책: 전체 동의는 모든 항목 체크만 하고, 선택 항목을 해제할 수 있도록 화면에 머무름.
                    // 하나라도 직접 체크했으면 필수 항목만 채운다(QA A5-3) — 선택 항목은 본인이 고른 그대로 둔다.
                    let requiredOnly = state.fillsRequiredOnly
                    Log.trace(requiredOnly ? "필수 항목 동의하기 실행" : "모두 동의하기 실행", category: .view, level: .debug)
                    state.rows.ids.forEach { id in
                        guard !requiredOnly || state.rows[id: id]?.term.type == .required else { return }
                        state.rows[id: id]?.isChecked = true
                    }
                    return .none
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
