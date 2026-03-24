//
//  SegmentControl.swift
//  DesignSystem
//
//  Created by suni on 3/13/26.
//

import SwiftUI

/// 두 개의 선택지를 가진 세그먼트 컨트롤 컴포넌트입니다.
///
/// 각 세그먼트는 타이틀과 서브타이틀을 가지며, 선택된 항목은 시각적으로 강조됩니다.
/// 디자인 시스템의 Segment Button 가이드를 따릅니다.
///
/// ## 사용 예시
/// ```swift
/// @State private var selectedSide: SegmentControl.Side = .left
///
/// SegmentControl(
///     leftItem: SegmentItem(title: "특기", subtitle: "탑포지션"),
///     rightItem: SegmentItem(title: "최애", subtitle: "가드포지션"),
///     selectedSide: selectedSide
/// ) { newSide in
///     selectedSide = newSide
/// }
/// ```
///
/// ## 파라미터
/// - `leftItem`: 왼쪽 세그먼트 아이템
/// - `rightItem`: 오른쪽 세그먼트 아이템
/// - `selectedSide`: 현재 선택된 쪽 (.left 또는 .right)
/// - `onSelectionChange`: 선택이 변경될 때 호출되는 클로저
public struct SegmentControl: View {
    
    // MARK: - Types
    
    /// 세그먼트의 왼쪽/오른쪽을 나타내는 열거형
    public enum Side: Equatable, Hashable {
        case left
        case right
    }
    
    // MARK: - Properties
    
    private let leftItem: SegmentItem
    private let rightItem: SegmentItem
    private let selectedSide: Side
    private let onSelectionChange: (Side) -> Void
    
    // MARK: - Metrics
    
    private enum Metrics {
        static let containerWidth: CGFloat = 262
        static let containerHeight: CGFloat = 67
        static let containerCornerRadius: CGFloat = 28
        static let itemCornerRadius: CGFloat = 24
        static let itemHeight: CGFloat = 59
        static let itemPadding: CGFloat = 4
        static let contentVerticalSpacing: CGFloat = 4
    }
    
    // MARK: - Initialization
    
    /// SegmentControl을 생성합니다.
    /// - Parameters:
    ///   - leftItem: 왼쪽 세그먼트 아이템
    ///   - rightItem: 오른쪽 세그먼트 아이템
    ///   - selectedSide: 현재 선택된 쪽
    ///   - onSelectionChange: 선택 변경 시 호출되는 클로저
    public init(
        leftItem: SegmentItem,
        rightItem: SegmentItem,
        selectedSide: Side,
        onSelectionChange: @escaping (Side) -> Void
    ) {
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.selectedSide = selectedSide
        self.onSelectionChange = onSelectionChange
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 0) {
            // 왼쪽 세그먼트
            SegmentButton(
                item: leftItem,
                isSelected: selectedSide == .left
            ) {
                onSelectionChange(.left)
            }
            
            // 오른쪽 세그먼트
            SegmentButton(
                item: rightItem,
                isSelected: selectedSide == .right
            ) {
                onSelectionChange(.right)
            }
        }
        .frame(width: Metrics.containerWidth, height: Metrics.containerHeight)
        .background(Color.component.segment.container.bg)
        .cornerRadius(Metrics.containerCornerRadius)
    }
}

// MARK: - Segment Item

/// 세그먼트 컨트롤의 개별 아이템을 정의합니다.
public struct SegmentItem: Equatable {
    /// 세그먼트의 주 제목
    public let title: String
    
    /// 세그먼트의 부제목 (작은 글씨)
    public let subtitle: String
    
    /// SegmentItem을 생성합니다.
    /// - Parameters:
    ///   - title: 주 제목
    ///   - subtitle: 부제목
    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Segment Button (Private)

/// 세그먼트 컨트롤의 개별 버튼 컴포넌트
private struct SegmentButton: View {
    let item: SegmentItem
    let isSelected: Bool
    let action: () -> Void
    
    private enum Metrics {
        static let itemCornerRadius: CGFloat = 24
        static let itemHeight: CGFloat = 59
        static let itemPadding: CGFloat = 4
        static let contentVerticalSpacing: CGFloat = 4
        static let titleFontSize: CGFloat = 18
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Metrics.contentVerticalSpacing) {
                // 타이틀
                Text(item.title)
                    .font(.pretendard.custom(weight: .semiBold, size: Metrics.titleFontSize))
                    .foregroundColor(
                        isSelected
                            ? Color.component.segment.selected.titleText
                            : Color.component.segment.unselected.titleText
                    )
                
                // 서브타이틀
                Text(item.subtitle)
                    .font(.pretendard.labelM)
                    .foregroundColor(
                        isSelected
                            ? Color.component.segment.selected.subText
                            : Color.component.segment.unselected.subText
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.itemHeight)
            .background(
                isSelected
                    ? Color.component.segment.selected.bg
                    : Color.component.segment.unselected.bg
            )
            .cornerRadius(Metrics.itemCornerRadius)
            .padding(Metrics.itemPadding)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("SegmentControl - Basic") {
    VStack(spacing: 40) {
        // 왼쪽 선택됨
        SegmentControl(
            leftItem: SegmentItem(title: "특기", subtitle: "탑포지션"),
            rightItem: SegmentItem(title: "최애", subtitle: "가드포지션"),
            selectedSide: .left
        ) { _ in }
        
        // 오른쪽 선택됨
        SegmentControl(
            leftItem: SegmentItem(title: "특기", subtitle: "탑포지션"),
            rightItem: SegmentItem(title: "최애", subtitle: "가드포지션"),
            selectedSide: .right
        ) { _ in }
    }
    .padding()
    .background(Color.component.background.default)
}

#Preview("SegmentControl - Interactive") {
    struct InteractivePreview: View {
        @State private var selectedSide: SegmentControl.Side = .left
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selectedSide == .left ? "Left" : "Right")")
                    .font(.pretendard.bodyM)
                
                SegmentControl(
                    leftItem: SegmentItem(title: "특기", subtitle: "탑포지션"),
                    rightItem: SegmentItem(title: "최애", subtitle: "가드포지션"),
                    selectedSide: selectedSide
                ) { newSide in
                    selectedSide = newSide
                }
                
                // 동적 subtitle 예시
                SegmentControl(
                    leftItem: SegmentItem(
                        title: "포지션",
                        subtitle: selectedSide == .left ? "탑포지션 선택됨" : "탑포지션"
                    ),
                    rightItem: SegmentItem(
                        title: "서브미션",
                        subtitle: selectedSide == .right ? "암바 선택됨" : "암바"
                    ),
                    selectedSide: selectedSide
                ) { newSide in
                    selectedSide = newSide
                }
            }
            .padding()
            .background(Color.component.background.default)
        }
    }
    
    return InteractivePreview()
}

#Preview("SegmentControl - Various Content") {
    VStack(spacing: 30) {
        // 짧은 텍스트
        SegmentControl(
            leftItem: SegmentItem(title: "A", subtitle: "Short"),
            rightItem: SegmentItem(title: "B", subtitle: "Text"),
            selectedSide: .left
        ) { _ in }
        
        // 긴 텍스트
        SegmentControl(
            leftItem: SegmentItem(title: "포지션 설정", subtitle: "탑포지션 스타일"),
            rightItem: SegmentItem(title: "기술 설정", subtitle: "가드패스 스타일"),
            selectedSide: .right
        ) { _ in }
        
        // 숫자 포함
        SegmentControl(
            leftItem: SegmentItem(title: "레벨 1", subtitle: "초급자"),
            rightItem: SegmentItem(title: "레벨 2", subtitle: "중급자"),
            selectedSide: .left
        ) { _ in }
    }
    .padding()
    .background(Color.component.background.default)
}
