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

    /// 텍스트 왼쪽에 붙일 아이콘을 반환하는 클로저 (없으면 텍스트만 표시)
    let icon: ((Item) -> Image)?

    /// 항목 선택 시 호출되는 클로저
    let onSelect: (Item) -> Void

    /// 피커의 너비 (기본값: 130)
    let width: CGFloat

    /// 각 항목의 높이 (기본값: 45)
    let itemHeight: CGFloat

    /// 항목 간 간격 (기본값: 8)
    let itemSpacing: CGFloat

    // MARK: - State

    /// 스크롤 위치. 항목 id가 아니라 "몇 번째 슬롯 × 슬롯 높이" 오프셋으로 움직인다.
    /// id 기준(`scrollPosition(id:)`)으로 처음 위치를 잡으면 항목에 따라 중앙에서 항목 간격만큼 어긋나
    /// 나란히 둔 피커끼리 높이가 달라 보였다(대회 날짜의 한 자리 월). 오프셋은 격자와 같은 계산이라 어긋나지 않는다.
    @State private var position: ScrollPosition

    /// 지금 화면 중앙에 있는 항목의 인덱스 — 강조 표시와 선택 전달의 기준
    @State private var centeredIndex: Int

    /// 사용자가 끌거나 관성으로 흐르는 중인지. 이때만 중앙 항목 변화를 선택으로 전달한다.
    @State private var isUserScrolling = false

    // MARK: - Initialization

    /// SheetPickerView 초기화
    /// - Parameters:
    ///   - items: 표시할 항목 배열
    ///   - selectedItem: 현재 선택된 항목
    ///   - displayText: 각 항목의 표시 텍스트를 반환하는 클로저
    ///   - icon: 텍스트 왼쪽에 붙일 아이콘 (기본값: nil)
    ///   - width: 피커의 너비 (기본값: 130)
    ///   - itemHeight: 각 항목의 높이 (기본값: 45)
    ///   - itemSpacing: 항목 간 간격 (기본값: 8)
    ///   - onSelect: 항목 선택 시 호출되는 클로저
    public init(
        items: [Item],
        selectedItem: Item,
        displayText: @escaping (Item) -> String,
        icon: ((Item) -> Image)? = nil,
        width: CGFloat = 130,
        itemHeight: CGFloat = 45,
        itemSpacing: CGFloat = 8,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayText = displayText
        self.icon = icon
        self.width = width
        self.itemHeight = itemHeight
        self.itemSpacing = itemSpacing
        self.onSelect = onSelect
        let initialIndex = items.firstIndex(of: selectedItem) ?? 0
        self._centeredIndex = State(initialValue: initialIndex)
        self._position = State(initialValue: ScrollPosition(y: Self.offset(for: initialIndex, pitch: itemHeight + itemSpacing)))
    }

    // MARK: - Layout Metrics

    /// 스냅 격자의 기준이 되는 한 슬롯(항목 높이 + 간격)의 높이
    private var slotPitch: CGFloat { itemHeight + itemSpacing }

    /// 정확히 3개 항목이 노출되는 뷰포트 높이
    private var viewportHeight: CGFloat { itemHeight * 3 + itemSpacing * 2 }

    /// `index` 항목이 중앙에 오는 스크롤 오프셋.
    /// 오프셋 0은 위 여백(한 슬롯)이 다 올라간 상태라 그때 중앙에는 두 번째 항목이 온다. 그래서 한 슬롯을 뺀다.
    private static func offset(for index: Int, pitch: CGFloat) -> CGFloat {
        CGFloat(index - 1) * pitch
    }

    // MARK: - Body

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: itemSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    pickerItemView(item, index: index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($position)
        // 자유 스크롤 대신 슬롯 격자에 스냅 → 손을 떼면 항상 항목이 정확히 중앙에 정렬되어
        // 여러 피커를 나란히 둘 때 행끼리 수평 정렬이 어긋나지 않는다.
        .scrollTargetBehavior(SlotSnapScrollBehavior(pitch: slotPitch))
        // 첫/마지막 항목도 중앙까지 올라올 수 있도록 위·아래로 한 슬롯만큼 스크롤 여백을 둔다.
        // 이 여백 덕분에 스크롤 오프셋 0에서 첫 항목이 중앙에 정렬된다.
        .contentMargins(.vertical, slotPitch, for: .scrollContent)
        .frame(width: width, height: viewportHeight)
        .onScrollGeometryChange(for: Int.self) { geometry in
            // 위 여백(contentInsets.top)을 더해 "첫 항목이 중앙일 때 0"이 되도록 맞춘 뒤 슬롯 단위로 반올림
            Int(((geometry.contentOffset.y + geometry.contentInsets.top) / slotPitch).rounded())
        } action: { _, newIndex in
            centeredIndex = min(max(newIndex, 0), items.count - 1)
            if isUserScrolling { selectCenteredItem() }
        }
        .onScrollPhaseChange { _, newPhase in
            isUserScrolling = newPhase == .interacting || newPhase == .decelerating
            // 손을 떼고 스냅까지 끝난 시점에도 한 번 더 전달해, 마지막 칸이 빠지지 않게 한다.
            if newPhase == .idle { selectCenteredItem() }
        }
        .onChange(of: selectedItem.id) { _, newID in
            // 외부에서 선택이 바뀐 경우에만 해당 항목으로 스크롤 (사용자 스크롤 → onSelect → 재스크롤 피드백 루프 방지)
            // 손으로 굴리는 중에는 한 박자 늦게 돌아온 선택값으로 되감지 않는다 — 멈춘 뒤 중앙 항목이 다시 전달된다.
            guard !isUserScrolling,
                  let index = items.firstIndex(where: { $0.id == newID }), index != centeredIndex else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                position.scrollTo(y: Self.offset(for: index, pitch: slotPitch))
            }
        }
    }

    /// 중앙 항목이 현재 선택과 다르면 선택을 전달한다.
    private func selectCenteredItem() {
        guard items.indices.contains(centeredIndex) else { return }
        let item = items[centeredIndex]
        guard item.id != selectedItem.id else { return }
        onSelect(item)
    }

    // MARK: - Private Views

    @ViewBuilder
    private func pickerItemView(_ item: Item, index: Int) -> some View {
        let isSelected = centeredIndex == index
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                position.scrollTo(y: Self.offset(for: index, pitch: slotPitch))
            }
            if item.id != selectedItem.id {
                onSelect(item)
            }
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    // 스크롤 중에도 항목을 글자보다 먼저 알아보도록 선택 여부와 상관없이 아이콘을 보여 준다
                    icon(item)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isSelected ? 24 : 20, height: isSelected ? 24 : 20)
                }

                Text(displayText(item))
                    .font(isSelected
                          ? .pretendard.custom(weight: .medium, size: 24)
                          : .pretendard.custom(weight: .medium, size: 20))
                    .foregroundStyle(isSelected
                                     ? Color.component.picker.itemSelectedText
                                     : Color.component.picker.itemUnselectedText)
            }
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
