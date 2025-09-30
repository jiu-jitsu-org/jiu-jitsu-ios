//
//  TermsAgreementSheetRowView.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

import SwiftUI

// MARK: - 바텀시트의 각 행 View
struct TermsAgreementSheetRowView: View {
    @Binding var item: TermsAgreementSheetItem
    let onRowTapped: (UUID) -> Void

    var body: some View {
        HStack(spacing: 9) {
            // 체크마크 버튼
            Button(action: {
                item.isChecked.toggle()
            }) {
                Assets.Login.Icon.check.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(item.isChecked ? Color.component.bottomSheet.selected.listItem.leadingIcon : Color.component.bottomSheet.unselected.listItem.leadingIcon)
            }
            
            // 텍스트
            Text(item.title)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(item.isChecked ? Color.component.bottomSheet.selected.listItem.label : Color.component.bottomSheet.unselected.listItem.label)
            
            Text(item.type.text)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(item.isChecked ? item.type.selectedColor : item.type.unselectedColor)
            
            Spacer()
            
            // 상세보기 버튼
            Button(action: {
                onRowTapped(item.id)
            }) {
                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(item.isChecked ? Color.component.bottomSheet.selected.listItem.followingIcon : Color.component.bottomSheet.unselected.listItem.followingIcon)
            }
        }
    }
}
