//
//  TermsAgreementRowFeature.swift
//  Presentation
//
//  Created by suni on 10/4/25.
//

import Foundation
import ComposableArchitecture
import DesignSystem
import Domain

@Reducer
public struct TermsAgreementRowFeature {
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
        
//        var leadingIconColor: Color {
//            isChecked ? Color.component.bottomSheet.selected.listItem.leadingIcon : Color.component.bottomSheet.unselected.listItem.leadingIcon
//        }
//        
//        var labelColor: Color {
//            isChecked ? Color.component.bottomSheet.selected.listItem.label : Color.component.bottomSheet.unselected.listItem.label
//        }
//        
//        var typeTextColor: Color {
//            isChecked ? (
//                term.type == .required ? Color.component.bottomSheet.selected.listItem.labelRequired : Color.component.bottomSheet.selected.listItem.labelOptional
//            ) : (
//                term.type == .required ? Color.component.bottomSheet.unselected.listItem.labelRequired : Color.component.bottomSheet.unselected.listItem.labelOptional
//            )
//        }
//        
//        var followingIconColor: Color {
//            isChecked ? Color.component.bottomSheet.selected.listItem.followingIcon : Color.component.bottomSheet.unselected.listItem.followingIcon
//        }
    }
    
    public enum Action: Equatable {
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
