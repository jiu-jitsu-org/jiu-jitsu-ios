//
//  BeltSettingView.swift
//  Presentation
//
//  Created by suni on 1/26/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

public struct BeltSettingView: View {
    
    @Bindable var store: StoreOf<BeltSettingFeature>
    
    public init(store: StoreOf<BeltSettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            pickerSection
            confirmButton
        }
        .background(Color.component.bottomSheet.selected.container.background)
    }
    
    // MARK: - View Components
    
    private var handleBar: some View {
        ZStack {
            Capsule()
                .fill(Color.component.bottomSheet.selected.container.handle)
                .frame(width: 48, height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
    }
    
    private var titleSection: some View {
        VStack {
            Spacer()
            Text("벨트")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 20)
    }
    
    private var pickerSection: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // 벨트 색상 피커
            SheetPickerView(
                items: Array(BeltRank.allCases.reversed()),
                selectedItem: store.selectedRank,
                displayText: { $0.displayName },
                onSelect: { rank in
                    store.send(.view(.rankSelected(rank)))
                }
            )
            
            // 벨트 그랄 피커
            SheetPickerView(
                items: Array(BeltStripe.allCases.reversed()),
                selectedItem: store.selectedStripe,
                displayText: { $0.displayName },
                onSelect: { stripe in
                    store.send(.view(.stripeSelected(stripe)))
                }
            )
            
            Spacer()
        }
        .padding(.vertical, 28)
    }
    
    private var confirmButton: some View {
        CTAButton(
            title: store.isInitialSetup ? "체급도 입력하기" : "확인",
            action: {
                store.send(.view(.confirmButtonTapped))
            }
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    BeltSettingView(
        store: Store(
            initialState: BeltSettingFeature.State()
        ) {
            BeltSettingFeature()
        }
    )
}
