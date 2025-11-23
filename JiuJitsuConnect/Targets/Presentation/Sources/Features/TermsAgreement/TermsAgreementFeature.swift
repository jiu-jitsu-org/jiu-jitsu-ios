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
public struct TermsAgreementFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var rows: IdentifiedArrayOf<TermsAgreementRowFeature.State>
        
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
                if state.didAgreeToAllRequired {
                    Log.trace("필수 약관 동의 완료 -> 다음 화면 이동", category: .view, level: .debug)
                    return .send(.delegate(.didFinishAgreement(isMarketingAgreed: state.isMarketingAgreed)))
                    
                } else {
                    Log.trace("모두 동의하기 실행", category: .view, level: .debug)
                    // 모든 항목 체크 처리
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
                return .run { _ in await openURL(url) }
                
            case .rows, .delegate:
                return .none
            }
        }
        .forEach(\.rows, action: \.rows) {
            TermsAgreementRowFeature()
        }
    }
}
