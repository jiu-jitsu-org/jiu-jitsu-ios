//
//  TermsAgreementRowView.swift
//  Presentation
//
//  Created by suni on 10/4/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

struct TermsAgreementRowView: View {
    let store: StoreOf<TermsAgreementRowFeature>
    
    var body: some View {
        TermsAgreementRow(
            // --- UI에 필요한 값 전달 ---
            title: store.term.title,
            typeText: store.term.type == .required ? "필수" : "선택",
            isChecked: store.isChecked,
            leadingIconColor: store.isChecked ? Color.component.bottomSheet.selected.listItem.leadingIcon : Color.component.bottomSheet.unselected.listItem.leadingIcon,
            labelColor: store.isChecked ? Color.component.bottomSheet.selected.listItem.label : Color.component.bottomSheet.unselected.listItem.label,
            typeTextColor:
                store.isChecked ? (
                    store.term.type == .required ? Color.component.bottomSheet.selected.listItem.labelRequired : Color.component.bottomSheet.selected.listItem.labelOptional
                ) : (
                    store.term.type == .required ? Color.component.bottomSheet.unselected.listItem.labelRequired : Color.component.bottomSheet.unselected.listItem.labelOptional
                ),
            followingIconColor: store.isChecked ? Color.component.bottomSheet.selected.listItem.followingIcon : Color.component.bottomSheet.unselected.listItem.followingIcon,
            
            onCheckTapped: { store.send(.checkTapped) },
            onSeeDetailsTapped: { store.send(.seeDetailsTapped) }
        )
    }
}
