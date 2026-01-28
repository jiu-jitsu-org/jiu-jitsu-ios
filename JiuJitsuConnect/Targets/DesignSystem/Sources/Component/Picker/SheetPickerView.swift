//
//  SheetPickerView.swift
//  DesignSystem
//
//  Created by suni on 1/28/26.
//

import SwiftUI

/// 바텀 시트에서 사용되는 휠 스타일 피커 뷰
///
/// 3개의 항목을 표시하며 중앙에 선택된 항목이 강조 표시됩니다.
/// 스크롤을 통해 항목을 선택할 수 있으며, 선택된 항목은 시각적으로 구분됩니다.
///
/// ## 사용 예시
/// ```swift
/// struct MyItem: Identifiable, Hashable {
///     let id: String
///     let displayText: String
/// }
///
/// SheetPickerView(
///     items: myItems,
///     selectedItem: selectedItem,
///     displayText: { $0.displayText },
///     onSelect: { item in
///         // 선택 처리
///     }
/// )
/// ```
public struct SheetPickerView<Item: Identifiable & Hashable>: View {
    
    // MARK: - Properties
    
    /// 표시할 항목 배열
    let items: [Item]
    
    /// 현재 선택된 항목
    let selectedItem: Item
    
    /// 항목의 표시 텍스트를 반환하는 클로저
    let displayText: (Item) -> String
    
    /// 항목 선택 시 호출되는 클로저
    let onSelect: (Item) -> Void
    
    /// 피커의 너비 (기본값: 130)
    let width: CGFloat
    
    /// 각 항목의 높이 (기본값: 45)
    let itemHeight: CGFloat
    
    /// 항목 간 간격 (기본값: 8)
    let itemSpacing: CGFloat
    
    // MARK: - State
    
    @State private var scrollPosition: Item.ID?
    
    // MARK: - Initialization
    
    /// SheetPickerView 초기화
    /// - Parameters:
    ///   - items: 표시할 항목 배열
    ///   - selectedItem: 현재 선택된 항목
    ///   - displayText: 각 항목의 표시 텍스트를 반환하는 클로저
    ///   - width: 피커의 너비 (기본값: 130)
    ///   - itemHeight: 각 항목의 높이 (기본값: 45)
    ///   - itemSpacing: 항목 간 간격 (기본값: 8)
    ///   - onSelect: 항목 선택 시 호출되는 클로저
    public init(
        items: [Item],
        selectedItem: Item,
        displayText: @escaping (Item) -> String,
        width: CGFloat = 130,
        itemHeight: CGFloat = 45,
        itemSpacing: CGFloat = 8,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayText = displayText
        self.width = width
        self.itemHeight = itemHeight
        self.itemSpacing = itemSpacing
        self.onSelect = onSelect
        self._scrollPosition = State(initialValue: selectedItem.id)
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: itemSpacing) {
                // 상단 여백 (투명한 spacer 역할)
                Color.clear
                    .frame(height: itemHeight + itemSpacing)
                
                ForEach(items) { item in
                    pickerItemView(item)
                }
                
                // 하단 여백 (투명한 spacer 역할)
                Color.clear
                    .frame(height: itemHeight + itemSpacing)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .frame(width: width, height: itemHeight * 3 + itemSpacing * 2) // 정확히 3개 항목 노출
        .onAppear {
            scrollPosition = selectedItem.id
        }
        .onChange(of: selectedItem.id) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollPosition = newValue
            }
        }
        .onChange(of: scrollPosition) { _, newItemId in
            guard let newItemId,
                  let newItem = items.first(where: { $0.id == newItemId }),
                  newItem.id != selectedItem.id else {
                return
            }
            onSelect(newItem)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func pickerItemView(_ item: Item) -> some View {
        let isSelected = item.id == selectedItem.id
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollPosition = item.id
                onSelect(item)
            }
        }) {
            Text(displayText(item))
                .font(isSelected 
                      ? .pretendard.custom(weight: .medium, size: 24) 
                      : .pretendard.custom(weight: .medium, size: 20))
                .foregroundStyle(isSelected 
                                 ? Color.component.picker.itemSelectedText 
                                 : Color.component.picker.itemUnselectedText)
                .frame(maxWidth: .infinity)
                .frame(height: itemHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected 
                              ? Color.component.picker.itemSelectedBg 
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .id(item.id)
    }
}

// MARK: - Preview

#Preview("Color Picker") {
    struct ColorItem: Identifiable, Hashable {
        let id: String
        let name: String
    }
    
    let colors = [
        ColorItem(id: "red", name: "빨강"),
        ColorItem(id: "blue", name: "파랑"),
        ColorItem(id: "green", name: "초록"),
        ColorItem(id: "yellow", name: "노랑"),
        ColorItem(id: "purple", name: "보라")
    ]
    
    return SheetPickerView(
        items: colors,
        selectedItem: colors[1],
        displayText: { $0.name },
        onSelect: { _ in }
    )
    .background(Color.gray.opacity(0.1))
}

#Preview("Number Picker") {
    struct NumberItem: Identifiable, Hashable {
        let id: Int
        var displayValue: String { "\(id)" }
    }
    
    let numbers = (1...10).map { NumberItem(id: $0) }
    
    return SheetPickerView(
        items: numbers,
        selectedItem: numbers[4],
        displayText: { $0.displayValue },
        onSelect: { _ in }
    )
    .background(Color.gray.opacity(0.1))
}

#Preview("Size Picker") {
    enum Size: String, CaseIterable, Identifiable {
        case small = "S"
        case medium = "M"
        case large = "L"
        case extraLarge = "XL"
        case xxl = "XXL"
        
        var id: String { rawValue }
    }
    
    struct SizeWrapper: Identifiable, Hashable {
        let size: Size
        var id: String { size.id }
    }
    
    let sizes = Size.allCases.map { SizeWrapper(size: $0) }
    
    return SheetPickerView(
        items: sizes,
        selectedItem: sizes[1],
        displayText: { $0.size.rawValue },
        onSelect: { _ in }
    )
    .background(Color.gray.opacity(0.1))
}
