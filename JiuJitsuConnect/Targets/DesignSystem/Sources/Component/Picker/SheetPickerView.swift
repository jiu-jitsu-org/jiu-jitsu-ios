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

    /// 현재 화면 중앙에 정렬된 항목의 id.
    /// `scrollPosition(id:anchor:.center)`이 스크롤에 맞춰 갱신하고, 외부 선택 변경 시 여기에 써 넣어 해당 항목으로 스크롤한다.
    @State private var scrolledID: Item.ID?

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
        self._scrolledID = State(initialValue: selectedItem.id)
    }

    // MARK: - Layout Metrics

    /// 스냅 격자의 기준이 되는 한 슬롯(항목 높이 + 간격)의 높이
    private var slotPitch: CGFloat { itemHeight + itemSpacing }

    /// 정확히 3개 항목이 노출되는 뷰포트 높이
    private var viewportHeight: CGFloat { itemHeight * 3 + itemSpacing * 2 }

    // MARK: - Body

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: itemSpacing) {
                ForEach(items) { item in
                    pickerItemView(item)
                }
            }
            .scrollTargetLayout()
        }
        // 중앙 정렬은 아래 contentMargins + 스냅 격자가 전담한다.
        // anchor: .center를 함께 주면 초기 레이아웃에서 정렬이 이중 적용되어 선택 항목이 한 슬롯 밀린다.
        .scrollPosition(id: $scrolledID)
        // 자유 스크롤 대신 슬롯 격자에 스냅 → 손을 떼면 항상 항목이 정확히 중앙에 정렬되어
        // 여러 피커를 나란히 둘 때 행끼리 수평 정렬이 어긋나지 않는다.
        .scrollTargetBehavior(SlotSnapScrollBehavior(pitch: slotPitch))
        // 첫/마지막 항목도 중앙까지 올라올 수 있도록 위·아래로 한 슬롯만큼 스크롤 여백을 둔다.
        // 이 여백 덕분에 스크롤 오프셋 0에서 첫 항목이 중앙에 정렬된다.
        .contentMargins(.vertical, slotPitch, for: .scrollContent)
        .frame(width: width, height: viewportHeight)
        .onChange(of: scrolledID) { _, newID in
            // 사용자 스크롤로 중앙 항목이 바뀌면 선택을 전달 (외부 선택과 동일하면 무시)
            guard let newID, newID != selectedItem.id,
                  let item = items.first(where: { $0.id == newID }) else { return }
            onSelect(item)
        }
        .onChange(of: selectedItem.id) { _, newID in
            // 외부에서 선택이 바뀐 경우에만 해당 항목으로 스크롤 (사용자 스크롤 → onSelect → 재스크롤 피드백 루프 방지)
            guard scrolledID != newID else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                scrolledID = newID
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private func pickerItemView(_ item: Item) -> some View {
        let isSelected = scrolledID == item.id
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                scrolledID = item.id
            }
        } label: {
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
                .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scroll Snap Behavior

/// 스크롤 종료 지점을 슬롯(항목 높이 + 간격) 격자에 스냅시키는 동작.
///
/// 네이티브 `ScrollView`의 관성 스크롤은 임의 위치에서 멈추므로, 여러 피커를 나란히 둘 때
/// 컬럼마다 미세하게 다른 오프셋에 정착해 행 정렬이 어긋난다. 모든 피커가 동일한 격자에
/// 스냅하도록 강제해 항상 항목이 정확히 중앙에 정렬되게 한다.
private struct SlotSnapScrollBehavior: ScrollTargetBehavior {
    let pitch: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard pitch > 0 else { return }
        target.rect.origin.y = (target.rect.minY / pitch).rounded() * pitch
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
        onSelect: { _ in }
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
