//
//  WithdrawalView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

private enum Style {
    static let headerHeight: CGFloat = 44
    
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
}

// MARK: - Withdrawal View
public struct WithdrawalView: View {
    @Bindable var store: StoreOf<WithdrawalFeature>
    
    public init(store: StoreOf<WithdrawalFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
        
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { store.send(.backButtonTapped) }) {
                ZStack {
                    Assets.Common.Icon.chevronLeft.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("회원 탈퇴")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
            
            Spacer()
            
            Rectangle()
                .fill(.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top))
    }
}
