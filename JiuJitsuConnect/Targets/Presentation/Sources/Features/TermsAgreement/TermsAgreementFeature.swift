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

@Reducer
public struct TermsAgreementFeature {
    
    @ObservableState
    public struct State: Equatable {
        var rows: IdentifiedArrayOf<TermsAgreementRowFeature.State>
        
        // UseCase를 통해 Domain 모델을 받아와서 UI 모델로 변환
        public init(terms: [TermItem]? = nil) {
            let mockTerms: [TermItem] = [
                .init(title: "서비스 이용약관 동의", type: .required, contentURL: URL(string: "https://example.com/service")),
                .init(title: "개인정보 처리방침 동의", type: .required, contentURL: URL(string: "https://example.com/privacy")),
                .init(title: "만 14세 이상입니다.", type: .required),
                .init(title: "마케팅 정보 수신", type: .optional, contentURL: URL(string: "https://example.com/marketing"))
            ]
            
            self.rows = .init(uniqueElements: (terms ?? mockTerms).map {
                TermsAgreementRowFeature.State(term: $0)
            })
        }
    }
    
    public enum Action: Equatable {
        case rows(IdentifiedAction<TermsAgreementRowFeature.State.ID, TermsAgreementRowFeature.Action>)
        case allAgreeButtonTapped
        
        public enum Delegate: Equatable { case didAgree }
        case delegate(Delegate)
    }
    
    @Dependency(\.openURL) var openURL
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .allAgreeButtonTapped:
                // ✅ `rows` 배열의 각 요소는 `RowFeature.State`이므로, `term.type`과 `isChecked`로 접근합니다.
                let allRequiredAgreed = state.rows
                    .filter { $0.term.type == .required }
                    .allSatisfy { $0.isChecked }
                
                if allRequiredAgreed {
                    return .send(.delegate(.didAgree))
                } else {
                    // TODO: 필수 항목 동의 필요 토스트 로직
                    return .none
                }
                
            case .rows(.element(id: let id, action: .seeDetailsTapped)):
                // 'id'를 사용하여 특정 약관의 URL을 찾습니다.
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
