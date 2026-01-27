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
            // 상단 핸들
            ZStack {
                Capsule()
                    .fill(Color.component.bottomSheet.selected.container.handle)
                    .frame(width: 48, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            
            // 타이틀
            VStack {
                Spacer()
                Text("벨트")
                    .font(Font.pretendard.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .padding(.horizontal, 20)
            
            // 피커 영역
            HStack(spacing: 24) {
                Spacer()
                // 색상 피커
                BeltPickerView(
                    items: BeltRank.allCases.reversed(),
                    selectedItem: store.selectedRank,
                    onSelect: { rank in
                        store.send(.view(.rankSelected(rank)))
                    }
                )
                
                // 그랄 피커
                BeltPickerView(
                    items: BeltStripe.allCases.reversed(),
                    selectedItem: store.selectedStripe,
                    onSelect: { stripe in
                        store.send(.view(.stripeSelected(stripe)))
                    }
                )
                Spacer()
            }
            .padding(.vertical, 28)
            
            // CTA 버튼
            CTAButton(title: "체급도 입력하기", action: {
                store.send(.view(.confirmButtonTapped))
            })
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(
            Color.component.bottomSheet.selected.container.background
        )
    }
}

// MARK: - BeltPickerView

/// Belt 관련 타입을 위한 프로토콜
private protocol BeltDisplayable {
    var displayName: String { get }
}

extension BeltRank: BeltDisplayable {}
extension BeltStripe: BeltDisplayable {}

private struct BeltPickerView<Item: Hashable & CaseIterable & BeltDisplayable>: View {
    let items: [Item]
    let selectedItem: Item
    let onSelect: (Item) -> Void
    
    @State private var scrollPosition: Item?
    
    private let itemHeight: CGFloat = 45
    private let itemSpacing: CGFloat = 8
    
    init(items: [Item], selectedItem: Item, onSelect: @escaping (Item) -> Void) {
        self.items = items
        self.selectedItem = selectedItem
        self.onSelect = onSelect
        self._scrollPosition = State(initialValue: selectedItem)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: itemSpacing) {
                // 상단 여백 (투명한 spacer 역할)
                Color.clear
                    .frame(height: itemHeight + itemSpacing)
                
                ForEach(items, id: \.self) { item in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scrollPosition = item
                            onSelect(item)
                        }
                    }) {
                        Text(item.displayName)
                            .font(selectedItem == item ? .pretendard.custom(weight: .medium, size: 24) : .pretendard.custom(weight: .medium, size: 20))
                            .foregroundStyle(selectedItem == item ? Color.component.picker.itemSelectedText : Color.component.picker.itemUnselectedText)
                            .frame(maxWidth: .infinity)
                            .frame(height: itemHeight)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedItem == item ? Color.component.picker.itemSelectedBg : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .id(item)
                }
                
                // 하단 여백 (투명한 spacer 역할)
                Color.clear
                    .frame(height: itemHeight + itemSpacing)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .frame(width: 130, height: itemHeight * 3 + itemSpacing * 2) // 정확히 3개 항목 노출
        .onAppear {
            scrollPosition = selectedItem
        }
        .onChange(of: selectedItem) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollPosition = newValue
            }
        }
        .onChange(of: scrollPosition) { _, newValue in
            if let newValue, newValue != selectedItem {
                onSelect(newValue)
            }
        }
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
