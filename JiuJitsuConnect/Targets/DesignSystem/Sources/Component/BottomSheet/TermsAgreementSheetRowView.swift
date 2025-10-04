//
//  TermsAgreementSheetRowView.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

import SwiftUI

public struct TermsAgreementRow: View {
    let title: String
    let typeText: String
    let isChecked: Bool
    let leadingIconColor: Color
    let labelColor: Color
    let typeTextColor: Color
    let followingIconColor: Color
    
    let onCheckTapped: () -> Void
    let onSeeDetailsTapped: () -> Void

    public init(title: String, typeText: String, isChecked: Bool, leadingIconColor: Color, labelColor: Color, typeTextColor: Color, followingIconColor: Color, onCheckTapped: @escaping () -> Void, onSeeDetailsTapped: @escaping () -> Void) {
        self.title = title
        self.typeText = typeText
        self.isChecked = isChecked
        self.leadingIconColor = leadingIconColor
        self.labelColor = labelColor
        self.typeTextColor = typeTextColor
        self.followingIconColor = followingIconColor
        self.onCheckTapped = onCheckTapped
        self.onSeeDetailsTapped = onSeeDetailsTapped
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 9) {
                Assets.Login.Icon.check.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isChecked ? Color.component.bottomSheet.selected.listItem.leadingIcon : Color.component.bottomSheet.unselected.listItem.leadingIcon)
                    .padding(.leading, 8)
                
                Text(title)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(isChecked ? Color.component.bottomSheet.selected.listItem.label : Color.component.bottomSheet.unselected.listItem.label)
                
                Text(typeText)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(typeTextColor)
                    .padding(.trailing, 8)
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .onTapGesture {
                onCheckTapped()
            }
            
            Spacer()
            
            // 상세보기 버튼
            Button(action: {
                onSeeDetailsTapped()
            }) {
                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isChecked ? Color.component.bottomSheet.selected.listItem.followingIcon : Color.component.bottomSheet.unselected.listItem.followingIcon)
            }
            .frame(width: 40, height: 40)
        }
    }
}
