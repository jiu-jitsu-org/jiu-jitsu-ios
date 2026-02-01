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
    
    @State private var currentSelectedId: Item.ID
    @State private var scrollOffset: CGFloat = 0
    
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
        self._currentSelectedId = State(initialValue: selectedItem.id)
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollViewReader { proxy in
            contentView(proxy: proxy)
        }
    }
    
    @ViewBuilder
    private func contentView(proxy: ScrollViewProxy) -> some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: itemSpacing) {
                    // 상단 여백 (투명한 spacer 역할)
                    Color.clear
                        .frame(height: itemHeight + itemSpacing)
                    
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        pickerItemView(item, index: index, proxy: proxy, geometryProxy: geometry)
                    }
                    
                    // 하단 여백 (투명한 spacer 역할)
                    Color.clear
                        .frame(height: itemHeight + itemSpacing)
                }
            }
            .frame(width: width, height: itemHeight * 3 + itemSpacing * 2) // 정확히 3개 항목 노출
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        // 드래그 종료 시 가장 가까운 항목으로 스냅
                        snapToNearestItem(proxy: proxy, geometry: geometry)
                    }
            )
        }
        .frame(width: width, height: itemHeight * 3 + itemSpacing * 2)
        .onAppear {
            currentSelectedId = selectedItem.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                proxy.scrollTo(selectedItem.id, anchor: .center)
            }
        }
        .onChange(of: selectedItem.id) { _, newValue in
            currentSelectedId = newValue
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(newValue, anchor: .center)
            }
        }
    }
    
    // 가장 가까운 항목으로 스냅
    private func snapToNearestItem(proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let centerY = geometry.size.height / 2
        
        var closestItem: Item?
        var minDistance: CGFloat = .infinity
        
        for (index, item) in items.enumerated() {
            let itemCenterY = CGFloat(index) * (itemHeight + itemSpacing) + itemHeight / 2
            let distance = abs(itemCenterY - centerY - scrollOffset)
            
            if distance < minDistance {
                minDistance = distance
                closestItem = item
            }
        }
        
        if let item = closestItem, item.id != currentSelectedId {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(item.id, anchor: .center)
                currentSelectedId = item.id
            }
            onSelect(item)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func pickerItemView(_ item: Item, index: Int, proxy: ScrollViewProxy, geometryProxy: GeometryProxy) -> some View {
        GeometryReader { itemGeometry in
            let globalFrame = itemGeometry.frame(in: .global)
            let containerFrame = geometryProxy.frame(in: .global)
            let containerCenter = containerFrame.midY
            let itemCenter = globalFrame.midY
            let distance = abs(containerCenter - itemCenter)
            let isNearCenter = distance < itemHeight / 2
            
            Button(action: {
                currentSelectedId = item.id
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(item.id, anchor: .center)
                }
                onSelect(item)
            }) {
                Text(displayText(item))
                    .font(isNearCenter
                          ? .pretendard.custom(weight: .medium, size: 24)
                          : .pretendard.custom(weight: .medium, size: 20))
                    .foregroundStyle(isNearCenter
                                     ? Color.component.picker.itemSelectedText
                                     : Color.component.picker.itemUnselectedText)
                    .frame(maxWidth: .infinity)
                    .frame(height: itemHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isNearCenter
                                  ? Color.component.picker.itemSelectedBg
                                  : Color.clear)
                    )
                    .animation(.easeOut(duration: 0.15), value: isNearCenter)
            }
            .buttonStyle(.plain)
            .onChange(of: isNearCenter) { _, newValue in
                if newValue && item.id != currentSelectedId {
                    currentSelectedId = item.id
                    onSelect(item)
                }
            }
        }
        .frame(height: itemHeight)
        .id(item.id)
    }
}

// MARK: - Preview

#Preview("Belt Stripe - Default None") {
    // BeltStripe는 import가 필요하므로 여기서는 wrapper 사용
    struct StripeItem: Identifiable, Hashable {
        let id: String
        let name: String
        
        static let items = [
            StripeItem(id: "STRIPE_4", name: "4그랄"),
            StripeItem(id: "STRIPE_3", name: "3그랄"),
            StripeItem(id: "STRIPE_2", name: "2그랄"),
            StripeItem(id: "STRIPE_1", name: "1그랄"),
            StripeItem(id: "STRIPE_0", name: "무그랄")
        ]
    }
    
    // .none (STRIPE_0)이 맨 마지막에 있음 (reversed)
    return SheetPickerView(
        items: StripeItem.items,
        selectedItem: StripeItem.items.last!, // STRIPE_0 선택
        displayText: { $0.name },
        onSelect: { item in
            print("Selected: \(item.name)")
        }
    )
    .background(Color.gray.opacity(0.1))
    .frame(height: 300)
}

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
