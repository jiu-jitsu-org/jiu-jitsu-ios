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
            title: store.term.title,
            typeText: store.typeText,
            isChecked: store.isChecked,
            leadingIconColor: leadingIconColor,
            labelColor: labelColor,
            typeTextColor: typeTextColor,
            followingIconColor: followingIconColor,
            onCheckTapped: { store.send(.checkTapped) },
            onSeeDetailsTapped: { store.send(.seeDetailsTapped) }
        )
    }
    
    // MARK: - Color Logic
    
    private var leadingIconColor: Color {
        store.isChecked
        ? Color.component.bottomSheet.selected.listItem.leadingIcon
        : Color.component.bottomSheet.unselected.listItem.leadingIcon
    }
    
    private var labelColor: Color {
        store.isChecked
        ? Color.component.bottomSheet.selected.listItem.label
        : Color.component.bottomSheet.unselected.listItem.label
    }
    
    private var typeTextColor: Color {
        if store.isChecked {
            return store.term.type == .required
            ? Color.component.bottomSheet.selected.listItem.labelRequired
            : Color.component.bottomSheet.selected.listItem.labelOptional
        } else {
            return store.term.type == .required
            ? Color.component.bottomSheet.unselected.listItem.labelRequired
            : Color.component.bottomSheet.unselected.listItem.labelOptional
        }
    }
    
    private var followingIconColor: Color {
        store.isChecked
        ? Color.component.bottomSheet.selected.listItem.followingIcon
        : Color.component.bottomSheet.unselected.listItem.followingIcon
    }
}
