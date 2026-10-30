//
//  SheetPickerView.swift
//  DesignSystem
//
//  Created by suni on 1/28/26.
//

import SwiftUI

/// 휠 피커를 손가락으로 굴릴 수 있는 영역
public enum SheetPickerDragArea: Equatable, Sendable {
    /// 보이는 칸 안에서만 굴린다 (기본)
    case viewport
    /// 받은 공간 전체 어디를 위아래로 끌어도 굴린다. 보이는 칸 밖 빈 곳은 투명한 끌기 영역이 된다.
    /// 선택 칸은 공간 세로 가운데에서 `verticalOffset`만큼 옮긴 자리에 온다(음수면 위로).
    /// 작은 화면에서 옮긴 만큼 위가 모자라면, 보이는 칸이 공간 위 끝에서 `minimumTopSpacing`보다 붙지 않게 내려 둔다.
    case fill(verticalOffset: CGFloat = 0, minimumTopSpacing: CGFloat = 0)
}

/// 휠 피커의 생김새
public enum SheetPickerStyle: Equatable, Sendable {
    /// 세 칸 (기본)
    case standard
    /// 다섯 칸. 가운데에서 멀수록 옅고 작아져 둥근 휠처럼 보이고,
    /// 처음 뜰 때 한 번 살짝 굴렀다 돌아와 굴릴 수 있다는 걸 알린다.
    case wheel

    /// 보이는 칸 수 (홀수)
    var visibleRowCount: Int {
        switch self {
        case .standard: return 3
        case .wheel: return 5
        }
    }
}

/// 바텀 시트에서 사용되는 휠 스타일 피커 뷰
///
/// 3개(`.wheel`은 5개)의 항목을 표시하며 중앙에 선택된 항목이 강조 표시됩니다.
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

    let items: [Item]
    let selectedItem: Item
    let displayText: (Item) -> String
    let icon: ((Item) -> Image)?
    let onSelect: (Item) -> Void
    let width: CGFloat
    let itemHeight: CGFloat
    let itemSpacing: CGFloat
    let dragArea: SheetPickerDragArea
    let style: SheetPickerStyle

    /// '굴릴 수 있다' 힌트를 이미 보였는지. 휠 본체가 크기 변화로 다시 그려져도 다시 보이지 않도록 바깥에 둔다.
    @State private var hasPlayedHint = false

    /// SheetPickerView 초기화
    /// - Parameters:
    ///   - items: 표시할 항목 배열
    ///   - selectedItem: 현재 선택된 항목
    ///   - displayText: 각 항목의 표시 텍스트를 반환하는 클로저
    ///   - icon: 텍스트 왼쪽에 붙일 아이콘 (기본값: nil)
    ///   - width: 피커의 너비 (기본값: 130)
    ///   - itemHeight: 각 항목의 높이 (기본값: 45)
    ///   - itemSpacing: 항목 간 간격 (기본값: 8)
    ///   - dragArea: 손가락으로 굴릴 수 있는 영역 (기본값: 보이는 칸)
    ///   - style: 생김새 (기본값: 세 칸)
    ///   - onSelect: 항목 선택 시 호출되는 클로저
    public init(
        items: [Item],
        selectedItem: Item,
        displayText: @escaping (Item) -> String,
        icon: ((Item) -> Image)? = nil,
        width: CGFloat = 130,
        itemHeight: CGFloat = 45,
        itemSpacing: CGFloat = 8,
        dragArea: SheetPickerDragArea = .viewport,
        style: SheetPickerStyle = .standard,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayText = displayText
        self.icon = icon
        self.width = width
        self.itemHeight = itemHeight
        self.itemSpacing = itemSpacing
        self.dragArea = dragArea
        self.style = style
        self.onSelect = onSelect
    }

    /// 보이는 칸이 모두 들어가는 높이
    private var viewportHeight: CGFloat {
        let rows = CGFloat(style.visibleRowCount)
        return itemHeight * rows + itemSpacing * (rows - 1)
    }

    public var body: some View {
        switch dragArea {
        case .viewport:
            wheel(frameHeight: viewportHeight, viewportTop: 0)
                .frame(width: width, height: viewportHeight)
        case let .fill(verticalOffset, minimumTopSpacing):
            // 받은 공간 전체를 스크롤 영역으로 써서 빈 곳을 끌어도 휠이 돈다.
            // 보이는 건 공간 세로 가운데(+ verticalOffset)의 칸들뿐이다.
            GeometryReader { proxy in
                let centered = (proxy.size.height - viewportHeight) / 2 + verticalOffset
                let lowest = max(minimumTopSpacing, proxy.size.height - viewportHeight)
                // 1pt 미만 흔들림으로 휠을 다시 그리지 않도록 정수 pt로 맞춘다.
                let viewportTop = min(max(minimumTopSpacing, centered), lowest).rounded()
                wheel(frameHeight: proxy.size.height, viewportTop: viewportTop)
                    // 칸 자리가 바뀌면 스크롤 기준점도 바뀐다. 이미 뜬 스크롤 뷰에서 여백과 위치를 함께 옮기면
                    // 위치가 맨 위로 튀어(첫 항목이 가운데) 고른 값과 어긋나므로, 새 자리에서 처음부터 다시 그린다.
                    // 다시 그리면 고른 값(selectedItem)에서 시작하므로, 멈춰 있을 때는 보이는 값이 바뀌지 않는다.
                    .id(viewportTop)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    private func wheel(frameHeight: CGFloat, viewportTop: CGFloat) -> some View {
        SheetPickerWheel(
            items: items,
            selectedItem: selectedItem,
            displayText: displayText,
            icon: icon,
            width: width,
            itemHeight: itemHeight,
            itemSpacing: itemSpacing,
            style: style,
            frameHeight: frameHeight,
            viewportTop: viewportTop,
            limitsTapToVisibleRows: dragArea != .viewport,
            hasPlayedHint: $hasPlayedHint,
            onSelect: onSelect
        )
    }
}

/// 휠 본체. 스크롤 영역(`frameHeight`) 안에서 위 끝으로부터 `viewportTop`만큼 내려온 곳에 칸들을 보인다.
private struct SheetPickerWheel<Item: Identifiable & Hashable>: View {

    // MARK: - Properties

    let items: [Item]
    let selectedItem: Item
    let displayText: (Item) -> String
    let icon: ((Item) -> Image)?
    let onSelect: (Item) -> Void
    let width: CGFloat
    let itemHeight: CGFloat
    let itemSpacing: CGFloat
    let style: SheetPickerStyle

    /// 스크롤 영역 전체 높이
    let frameHeight: CGFloat

    /// 스크롤 영역 위 끝에서 보이는 칸들의 위 끝까지 거리
    let viewportTop: CGFloat

    /// 보이는 칸 밖(가려진) 항목은 누르지 못하게 할지 — 넓힌 끌기 영역에서 빈 곳을 눌러도 값이 바뀌지 않게
    let limitsTapToVisibleRows: Bool

    /// 힌트를 이미 보였는지(화면에 뜬 동안 한 번만)
    @Binding var hasPlayedHint: Bool

    // MARK: - State

    /// 스크롤 위치. 항목 id가 아니라 "몇 번째 슬롯 × 슬롯 높이" 오프셋으로 움직인다.
    /// id 기준(`scrollPosition(id:)`)으로 처음 위치를 잡으면 항목에 따라 중앙에서 항목 간격만큼 어긋나
    /// 나란히 둔 피커끼리 높이가 달라 보였다(대회 날짜의 한 자리 월). 오프셋은 격자와 같은 계산이라 어긋나지 않는다.
    @State private var position: ScrollPosition

    /// 지금 화면 중앙에 있는 항목의 인덱스 — 강조 표시와 선택 전달의 기준
    @State private var centeredIndex: Int

    /// 사용자가 끌거나 관성으로 흐르는 중인지. 이때만 중앙 항목 변화를 선택으로 전달한다.
    @State private var isUserScrolling = false

    /// 가운데 칸에 와 있는 위치를 소수까지 센 값(1.5 = 두 번째와 세 번째 항목 사이). `.wheel`의 깊이 표현에 쓴다.
    @State private var scrolledRow: CGFloat

    /// 처음 뜰 때 한 번 보여 주는 '굴릴 수 있다' 힌트로 칸들을 잠깐 밀어 둔 정도(칸 단위)
    @State private var hintShift: CGFloat = 0

    // MARK: - Initialization

    init(
        items: [Item],
        selectedItem: Item,
        displayText: @escaping (Item) -> String,
        icon: ((Item) -> Image)?,
        width: CGFloat,
        itemHeight: CGFloat,
        itemSpacing: CGFloat,
        style: SheetPickerStyle,
        frameHeight: CGFloat,
        viewportTop: CGFloat,
        limitsTapToVisibleRows: Bool,
        hasPlayedHint: Binding<Bool>,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayText = displayText
        self.icon = icon
        self.width = width
        self.itemHeight = itemHeight
        self.itemSpacing = itemSpacing
        self.style = style
        self.frameHeight = frameHeight
        self.viewportTop = viewportTop
        self.limitsTapToVisibleRows = limitsTapToVisibleRows
        self._hasPlayedHint = hasPlayedHint
        self.onSelect = onSelect
        let pitch = itemHeight + itemSpacing
        let initialIndex = items.firstIndex(of: selectedItem) ?? 0
        self._centeredIndex = State(initialValue: initialIndex)
        self._scrolledRow = State(initialValue: CGFloat(initialIndex))
        self._position = State(initialValue: ScrollPosition(
            y: Self.offset(for: initialIndex, pitch: pitch, centerSlotTop: viewportTop + CGFloat(style.visibleRowCount / 2) * pitch)
        ))
    }

    // MARK: - Layout Metrics

    /// 스냅 격자의 기준이 되는 한 슬롯(항목 높이 + 간격)의 높이
    private var slotPitch: CGFloat { itemHeight + itemSpacing }

    /// 가운데 칸 위·아래로 보이는 칸 수
    private var rowsAroundCenter: Int { style.visibleRowCount / 2 }

    /// 스크롤 영역 위 끝에서 가운데 칸 위 끝까지의 거리. 세 칸짜리면 한 슬롯이다.
    private var centerSlotTop: CGFloat { viewportTop + CGFloat(rowsAroundCenter) * slotPitch }

    /// 보이는 칸이 모두 들어가는 높이
    private var viewportHeight: CGFloat {
        let rows = CGFloat(style.visibleRowCount)
        return itemHeight * rows + itemSpacing * (rows - 1)
    }

    /// `index` 항목이 중앙에 오는 스크롤 오프셋.
    /// 오프셋 0은 위 여백이 다 올라가 첫 항목이 스크롤 영역 맨 위에 붙은 상태다.
    /// 그 항목이 가운데 칸까지 내려오려면 가운데 칸 위 끝까지의 거리(`centerSlotTop`)만큼 빼야 한다.
    /// 세 칸짜리면 `centerSlotTop`이 한 슬롯이라 (index - 1) × 슬롯이 된다.
    private static func offset(for index: Int, pitch: CGFloat, centerSlotTop: CGFloat) -> CGFloat {
        CGFloat(index) * pitch - centerSlotTop
    }

    private func offset(for index: Int) -> CGFloat {
        Self.offset(for: index, pitch: slotPitch, centerSlotTop: centerSlotTop)
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: itemSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    pickerItemView(item, index: index)
                        .scaleEffect(depthScale(for: index))
                        .opacity(depthOpacity(for: index))
                        // 보이는 칸 밖 항목은 가려져 안 보이므로 눌리지 않게 한다 — 빈 곳을 누르면 끌기만 된다.
                        .allowsHitTesting(!limitsTapToVisibleRows || abs(index - centeredIndex) <= rowsAroundCenter)
                }
            }
            .frame(width: width)
            .frame(maxWidth: .infinity)
            .scrollTargetLayout()
        }
        // 힌트는 스크롤 위치 대신 휠 전체를 잠깐 옮겨 보인다(아래 mask는 제자리라 보이는 칸 틀은 그대로).
        .offset(y: -hintShift * slotPitch)
        .scrollPosition($position)
        // 자유 스크롤 대신 슬롯 격자에 스냅 → 손을 떼면 항상 항목이 정확히 중앙에 정렬되어
        // 여러 피커를 나란히 둘 때 행끼리 수평 정렬이 어긋나지 않는다.
        .scrollTargetBehavior(SlotSnapScrollBehavior(pitch: slotPitch))
        // 첫/마지막 항목도 가운데 칸까지 올 수 있도록 위·아래 여백을 둔다.
        // 위 여백이 가운데 칸 위 끝까지의 거리라, 스크롤을 맨 위로 올리면 첫 항목이 가운데 칸에 온다.
        .contentMargins(.top, centerSlotTop, for: .scrollContent)
        .contentMargins(.bottom, max(0, frameHeight - centerSlotTop - itemHeight), for: .scrollContent)
        // 넓힌 스크롤 영역에서도 보이는 건 정해 둔 칸들뿐이다.
        .mask(alignment: .top) {
            Rectangle()
                .frame(height: viewportHeight)
                .padding(.top, viewportTop)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            (geometry.contentOffset.y + geometry.contentInsets.top) / slotPitch
        } action: { _, newRow in
            guard style == .wheel else { return }
            scrolledRow = newRow
        }
        .onScrollGeometryChange(for: Int.self) { geometry in
            // 위 여백(contentInsets.top = 가운데 칸 위 끝까지 거리)을 더해 "첫 항목이 중앙일 때 0"이 되도록 맞춘 뒤 슬롯 단위로 반올림
            Int(((geometry.contentOffset.y + geometry.contentInsets.top) / slotPitch).rounded())
        } action: { _, newIndex in
            centeredIndex = min(max(newIndex, 0), items.count - 1)
            if isUserScrolling { selectCenteredItem() }
        }
        .onScrollPhaseChange { _, newPhase in
            let wasUserScrolling = isUserScrolling
            isUserScrolling = newPhase == .interacting || newPhase == .decelerating
            // 손을 떼고 스냅까지 끝난 시점에도 한 번 더 전달해, 마지막 칸이 빠지지 않게 한다.
            // 손으로 굴린 뒤의 idle만 본다 — 화면이 닫히며 레이아웃이 바뀌어 생기는 idle에서 전달하면
            // 이미 사라진 화면에 엉뚱한 칸이 선택으로 전달된다(TCA ifLet 경고).
            if newPhase == .idle, wasUserScrolling { selectCenteredItem() }
        }
        .onChange(of: selectedItem.id) { _, newID in
            // 외부에서 선택이 바뀐 경우에만 해당 항목으로 스크롤 (사용자 스크롤 → onSelect → 재스크롤 피드백 루프 방지)
            // 손으로 굴리는 중에는 한 박자 늦게 돌아온 선택값으로 되감지 않는다 — 멈춘 뒤 중앙 항목이 다시 전달된다.
            guard !isUserScrolling,
                  let index = items.firstIndex(where: { $0.id == newID }), index != centeredIndex else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                position.scrollTo(y: offset(for: index))
            }
        }
        .task {
            guard style == .wheel, !hasPlayedHint else { return }
            await playScrollHint()
        }
    }

    /// 처음 뜰 때 한 번, 다음 칸 쪽으로 반 칸 조금 못 미치게 밀렸다가 제자리로 튕겨 돌아온다(합쳐 0.5초).
    /// 스크롤 위치는 건드리지 않고 칸들을 그려지는 자리만 잠깐 옮긴다 — 그래서 선택이 전달될 일이 없고
    /// (8a1e89a: 손으로 굴린 게 아니면 전달하지 않음), 끝난 뒤 칸 정렬이 어긋날 일도 없다.
    /// 화면 전환이 끝난 뒤에 보이도록 잠깐 기다린다. 한 화면에서 한 번만 보인다(`hasPlayedHint`).
    private func playScrollHint() async {
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled, !hasPlayedHint, !isUserScrolling, items.count > 1 else { return }
        hasPlayedHint = true
        // 마지막 항목이면 위쪽 칸이 보이도록 반대로 민다.
        let direction: CGFloat = centeredIndex == items.count - 1 ? -1 : 1
        // 반 칸을 넘으면 옆 칸이 가운데처럼 보이므로 0.4칸만 민다.
        withAnimation(.easeOut(duration: 0.2)) {
            hintShift = direction * 0.4
        } completion: {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                hintShift = 0
            }
        }
    }

    /// 가운데 칸에서 몇 칸 떨어져 있는지(스크롤 중에도 연속으로)
    private func depthDistance(for index: Int) -> CGFloat {
        min(abs(CGFloat(index) - (scrolledRow + hintShift)), CGFloat(rowsAroundCenter) + 0.5)
    }

    /// 가운데에서 멀수록 작게 — 둥근 휠이 뒤로 넘어가는 것처럼 보이게 한다.
    private func depthScale(for index: Int) -> CGFloat {
        style == .wheel ? 1 - depthDistance(for: index) * 0.06 : 1
    }

    /// 가운데에서 멀수록 옅게
    private func depthOpacity(for index: Int) -> Double {
        style == .wheel ? Double(1 - depthDistance(for: index) * 0.3) : 1
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
                position.scrollTo(y: offset(for: index))
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

    /// `target.rect`는 위 여백까지 포함한 좌표라(0 = 첫 항목이 가운데 칸) 슬롯 배수가 곧 "항목이 가운데 칸에 딱 오는" 자리다.
    /// 위 여백이 한 슬롯이 아니어도(빈 곳까지 넓힌 휠) 그대로 맞는다.
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
