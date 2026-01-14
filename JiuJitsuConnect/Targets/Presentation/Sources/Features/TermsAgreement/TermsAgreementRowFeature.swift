//
//  TermsAgreementRowFeature.swift
//  Presentation
//
//  Created by suni on 10/4/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct TermsAgreementRowFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: UUID { term.id }
        
        let term: TermItem
        var isChecked: Bool = false
        
        public init(term: TermItem) {
            self.term = term
        }
        
        // Logic Helper
        var typeText: String {
            term.type == .required ? "필수" : "선택"
        }
    }
    
    public enum Action: Sendable {
        case checkTapped
        case seeDetailsTapped
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkTapped:
                state.isChecked.toggle()
                return .none
                
            case .seeDetailsTapped:
                // 상세 보기는 부모 Feature에서 처리
                return .none
            }
        }
    }
}
