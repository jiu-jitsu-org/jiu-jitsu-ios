//
//  AppButtonStyle.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public struct AppButtonStyle: ButtonStyle {
    private let style: ButtonStyleType
    private let size: ButtonSize
    private let hasRightIcon: Bool
    private let fixedWidth: CGFloat?
    private let fixedHeight: CGFloat?
    private let horizontalPadding: CGFloat?
    
    // View의 .disabled() 상태를 읽어옴
    @Environment(\.isEnabled) private var isEnabled
    
    public init(
        style: ButtonStyleType,
        size: ButtonSize,
        hasRightIcon: Bool = false,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        horizontalPadding: CGFloat? = nil
    ) {
        self.style = style
        self.size = size
        self.hasRightIcon = hasRightIcon
        self.fixedWidth = width
        self.fixedHeight = height
        self.horizontalPadding = horizontalPadding
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        // 상태(isEnabled, isPressed)에 따라 색상과 폰트를 디자인 토큰에서 가져옴
        let colors = getColors(isPressed: isPressed)
        let font = getFont()
        let padding = getPadding()
        let cornerRadius = getCornerRadius()
        
        configuration.label
            .font(font)
            .padding(padding)
            .frame(width: fixedWidth, height: fixedHeight)
            .frame(maxHeight: fixedHeight == nil ? .infinity : nil)
            .background(colors.background)
            .foregroundStyle(colors.foreground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }
    
    // 상태에 따른 색상을 반환하는 헬퍼 메서드
    private func getColors(isPressed: Bool) -> (background: Color, foreground: Color) {
        let componentColors = Color.component.button
        
        switch style {
        case .primary:
            if !isEnabled { return (componentColors.filled.disabledBg, componentColors.filled.disabledText) }
            if isPressed { return (componentColors.filled.pressedBg, componentColors.filled.pressedText) }
            return (componentColors.filled.defaultBg, componentColors.filled.defaultText)
            
        case .destructive:
            return (Color(hex: "#E52012"), componentColors.filled.defaultText)
            
        case .tint:
            if !isEnabled { return (componentColors.tint.disabledBg, componentColors.tint.disabledText) }
            if isPressed { return (componentColors.tint.pressedBg, componentColors.tint.pressedText) }
            return (componentColors.tint.defaultBg, componentColors.tint.defaultText)
            
        case .text:
            if !isEnabled { return (componentColors.text.disabledBg, componentColors.text.disabledText) }
            if isPressed { return (componentColors.text.pressedBg, componentColors.text.pressedText) }
            return (componentColors.text.defaultBg, componentColors.text.defaultText)

        case .neutral:
            if !isEnabled { return (componentColors.neutral.disabledBg, componentColors.neutral.disabledText) }
            if isPressed { return (componentColors.neutral.pressedBg, componentColors.neutral.pressedText) }
            return (componentColors.neutral.defaultBg, componentColors.neutral.defaultText)
        }
    }
    
    // 크기에 따른 폰트를 반환하는 헬퍼 메서드
    private func getFont() -> Font? {
        switch size {
        case .large: return .pretendard.buttonM
        case .medium: return .pretendard.buttonM
        case .small: return .pretendard.buttonS
        case .iconOnly: return nil
        }
    }
    
    // 크기에 따른 패딩을 반환하는 헬퍼 메서드
    private func getPadding() -> EdgeInsets {
        // horizontalPadding이 지정된 경우 좌우 패딩을 커스텀 값으로 적용
        if let padding = horizontalPadding {
            return EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        }
        
        switch size {
        case .large:
            return EdgeInsets(
                top: 0,
                leading: hasRightIcon ? 22 : 28,
                bottom: 0,
                // 오른쪽 아이콘이 있으면 오른쪽 패딩을 줄여서 균형을 맞춤
                trailing: hasRightIcon ? 18 : 28
            )
        case .medium:
            return EdgeInsets(
                top: 0,
                leading: hasRightIcon ? 16 : 20,
                bottom: 0,
                trailing: hasRightIcon ? 12 : 20
            )
        case .small:
            return EdgeInsets(
                top: 0,
                leading: hasRightIcon ? 10 : 16,
                bottom: 0,
                trailing: hasRightIcon ? 6 : 16
            )
        case .iconOnly:
            return EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
        }
    }
    
    // 크기에 따른 cornerRadius를 반환하는 헬퍼 메서드
    private func getCornerRadius() -> CGFloat {
        switch size {
        case .large: return 15
        case .medium: return 10
        case .small: return 10
        case .iconOnly: return 10
        }
    }
}
