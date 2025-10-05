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
            leadingIconColor: store.leadingIconColor,
            labelColor: store.labelColor,
            typeTextColor: store.typeTextColor,
            followingIconColor: store.followingIconColor,
            onCheckTapped: { store.send(.checkTapped) },
            onSeeDetailsTapped: { store.send(.seeDetailsTapped) }
        )
    }
}
