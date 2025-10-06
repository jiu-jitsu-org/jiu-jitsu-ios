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
import OSLog

@Reducer
public struct TermsAgreementFeature {
    
    @ObservableState
    public struct State: Equatable {
        var rows: IdentifiedArrayOf<TermsAgreementRowFeature.State>
        var buttonTitle: String {
            return didAgreeToAllRequired ? "다음" : "모두 동의하기"
        }
        var didAgreeToAllRequired: Bool {
            rows.filter { $0.term.type == .required }
                .allSatisfy { $0.isChecked }
        }
        var isMarketingAgreed: Bool {
            rows.first { $0.term.type == .optional }?.isChecked ?? false
        }
        
        private static let fixedTerms: [TermItem] = [
            .init(title: "서비스 이용약관 동의", type: .required, contentURL: URL(string: "https://example.com/service")),
            .init(title: "개인정보 처리방침 동의", type: .required, contentURL: URL(string: "https://example.com/privacy")),
            .init(title: "만 14세 이상입니다.", type: .required),
            .init(title: "마케팅 정보 수신", type: .optional, contentURL: URL(string: "https://example.com/marketing"))
        ]
        
        public init() {
            self.rows = .init(
                uniqueElements: Self.fixedTerms.map { TermsAgreementRowFeature.State(term: $0) }
            )
        }
    }
    
    public enum Action: Equatable {
        case rows(IdentifiedAction<TermsAgreementRowFeature.State.ID, TermsAgreementRowFeature.Action>)
        case mainButtonTapped
        
        public enum Delegate: Equatable {
            case didFinishAgreement(isMarketingAgreed: Bool)
        }
        case delegate(Delegate)
    }
    
    @Dependency(\.openURL) var openURL
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .mainButtonTapped:
                let isMarketingAgreed = state.isMarketingAgreed
                
                if state.didAgreeToAllRequired {
                    Logger.view.debug("다음 화면으로 이동")
                    return .send(.delegate(.didFinishAgreement(isMarketingAgreed: isMarketingAgreed)))
                } else {
                    for id in state.rows.ids {
                        state.rows[id: id]?.isChecked = true
                    }
                    Logger.view.debug("모두 동의 완료, 다음 화면으로 이동")
                    // 모두 동의 시, 마케팅 동의는 true가 됨
                    return .send(.delegate(.didFinishAgreement(isMarketingAgreed: true)))
                }
                
            case .rows(.element(id: let id, action: .seeDetailsTapped)):
                guard let row = state.rows[id: id], let url = row.term.contentURL else {
                    return .none
                }
                return .run { _ in await self.openURL(url) }
                
            case .rows, .delegate:
                return .none
            }
        }
        .forEach(\.rows, action: \.rows) {
            TermsAgreementRowFeature()
        }
    }
}
