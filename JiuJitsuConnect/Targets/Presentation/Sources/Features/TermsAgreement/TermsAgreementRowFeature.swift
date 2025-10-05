//
//  TermsAgreementRowFeature.swift
//  Presentation
//
//  Created by suni on 10/4/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

@Reducer
public struct TermsAgreementRowFeature {
    
    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: UUID { term.id }
        
        let term: TermItem
        var isChecked: Bool = false
        
        public init(term: TermItem) {
            self.term = term
        }
        
        var typeText: String {
            term.type == .required ? "필수" : "선택"
        }
        
        var leadingIconColor: Color {
            isChecked ? Color.component.bottomSheet.selected.listItem.leadingIcon : Color.component.bottomSheet.unselected.listItem.leadingIcon
        }
        
        var labelColor: Color {
            isChecked ? Color.component.bottomSheet.selected.listItem.label : Color.component.bottomSheet.unselected.listItem.label
        }
        
        var typeTextColor: Color {
            isChecked ? (
                term.type == .required ? Color.component.bottomSheet.selected.listItem.labelRequired : Color.component.bottomSheet.selected.listItem.labelOptional
            ) : (
                term.type == .required ? Color.component.bottomSheet.unselected.listItem.labelRequired : Color.component.bottomSheet.unselected.listItem.labelOptional
            )
        }
        
        var followingIconColor: Color {
            isChecked ? Color.component.bottomSheet.selected.listItem.followingIcon : Color.component.bottomSheet.unselected.listItem.followingIcon
        }
    }
    
    // MARK: - Action
    public enum Action: Equatable {
        case checkTapped
        case seeDetailsTapped
    }
    
    // MARK: - Reducer
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkTapped:
                state.isChecked.toggle()
                return .none
                
            case .seeDetailsTapped:
                // '상세보기' 탭 액션은 이 Reducer에서 직접 처리하지 않습니다.
                // 부모 Reducer(TermsAgreementFeature)가 이 액션을 감지하고,
                // 웹뷰를 띄우는 등의 Side Effect를 처리하게 됩니다.
                // 따라서 여기서는 아무 작업 없이 .none을 반환합니다.
                return .none
            }
        }
    }
}
