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
/// - `selectedSide`: 현재 선택된 쪽 (.left 또는 .right, 아직 고르지 않았으면 nil)
/// - `onSelectionChange`: 선택이 변경될 때 호출되는 클로저
public struct SegmentControl: View {
    
    // MARK: - Types
    
    /// 세그먼트의 왼쪽/오른쪽을 나타내는 열거형
    public enum Side: Equatable, Hashable {
        case left
        case right
    }

    /// 크기 — `regular`는 타이틀+서브타이틀 카드형, `compact`는 타이틀만 있는 한 줄형.
    ///
    /// `compact`는 화면의 주 질문이 따로 있을 때 그 조건을 고르는 용도로, 눈에 덜 띄게 작게 둔다.
    /// 폭은 정해 두지 않으므로 쓰는 곳에서 `.frame(width:)`로 정한다.
    public enum Size: Equatable, Hashable {
        case regular
        case compact
    }
    
    // MARK: - Properties
    
    private let leftItem: SegmentItem
    private let rightItem: SegmentItem
    private let selectedSide: Side?
    private let size: Size
    private let onSelectionChange: (Side) -> Void

    // MARK: - Initialization
    
    /// SegmentControl을 생성합니다.
    /// - Parameters:
    ///   - leftItem: 왼쪽 세그먼트 아이템
    ///   - rightItem: 오른쪽 세그먼트 아이템
    ///   - selectedSide: 현재 선택된 쪽. nil이면 어느 쪽도 선택되지 않은 모양으로 그린다.
    ///   - size: 크기 (기본 `regular`)
    ///   - onSelectionChange: 선택 변경 시 호출되는 클로저
    public init(
        leftItem: SegmentItem,
        rightItem: SegmentItem,
        selectedSide: Side?,
        size: Size = .regular,
        onSelectionChange: @escaping (Side) -> Void
    ) {
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.selectedSide = selectedSide
        self.size = size
        self.onSelectionChange = onSelectionChange
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 0) {
            // 왼쪽 세그먼트
            SegmentButton(
                item: leftItem,
                isSelected: selectedSide == .left,
                size: size
            ) {
                onSelectionChange(.left)
            }
            
            // 오른쪽 세그먼트
            SegmentButton(
                item: rightItem,
                isSelected: selectedSide == .right,
                size: size
            ) {
                onSelectionChange(.right)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.component.segment.container.bg)
        .cornerRadius(size.cornerRadius)
    }
}

// MARK: - Segment Item

/// 세그먼트 컨트롤의 개별 아이템을 정의합니다.
public struct SegmentItem: Equatable {
    /// 세그먼트의 주 제목
    public let title: String
    
    /// 세그먼트의 부제목 (작은 글씨). `compact`에서는 보이지 않는다.
    public let subtitle: String
    
    /// SegmentItem을 생성합니다.
    /// - Parameters:
    ///   - title: 주 제목
    ///   - subtitle: 부제목
    public init(title: String, subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Segment Button (Private)

/// 세그먼트 컨트롤의 개별 버튼 컴포넌트
private struct SegmentButton: View {
    let item: SegmentItem
    let isSelected: Bool
    let size: SegmentControl.Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                // 타이틀
                Text(item.title)
                    .font(.pretendard.custom(weight: .semiBold, size: size == .compact ? 14 : 18))
                    .foregroundColor(
                        isSelected
                            ? Color.component.segment.selected.titleText
                            : Color.component.segment.unselected.titleText
                    )
                
                // 서브타이틀
                if size == .regular {
                    Text(item.subtitle)
                        .font(.pretendard.labelM)
                        .foregroundColor(
                            isSelected
                                ? Color.component.segment.selected.subText
                                : Color.component.segment.unselected.subText
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.buttonHeight)
            .background(
                isSelected
                    ? Color.component.segment.selected.bg
                    : Color.component.segment.unselected.bg
            )
            .cornerRadius(size.buttonCornerRadius)
            .padding(size.inset)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Size Metrics

private extension SegmentControl.Size {
    var width: CGFloat? {
        switch self {
        case .regular: return 262
        case .compact: return nil
        }
    }

    var height: CGFloat {
        switch self {
        case .regular: return 67
        case .compact: return 44
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular: return 28
        case .compact: return 22
        }
    }

    var inset: CGFloat {
        switch self {
        case .regular: return 4
        case .compact: return 3
        }
    }

    var buttonHeight: CGFloat { height - inset * 2 }

    var buttonCornerRadius: CGFloat { cornerRadius - inset }
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
