//
//  CTAButton.swift
//  DesignSystem
//
//  Created by suni on 10/6/25.
//

import SwiftUI

/// 앱 전반에서 사용될 공통 CTA 버튼입니다.
/// - Parameters:
///   - title: 버튼에 표시될 텍스트
///   - type: 버튼의 색상 타입 (.dark, .blue, .text). 기본값은 .blue.
///   - style: 버튼의 모서리 스타일 (.rounded, .keypad). 기본값은 .rounded.
///   - height: 버튼의 높이. 기본값은 52.
///   - action: 버튼을 탭했을 때 실행될 클로저.
public struct CTAButton: View {
    let title: String
    let type: ButtonType
    let style: Style
    let height: CGFloat
    let action: () -> Void
    
    public enum ButtonType {
        case dark
        case blue
        case text
    }
    
    public enum Style {
        case rounded
        case keypad
    }
    
    public init(
        title: String,
        type: ButtonType = .blue,
        style: Style = .rounded,
        height: CGFloat = 51,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.style = style
        self.height = height
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard.buttonM)
                .id(title)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
        .buttonStyle(CTAButtonStyle(type: type, style: style, height: height))
    }
}

/// CTAButton의 실제 스타일을 정의하는 private struct 입니다.
private struct CTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    let type: CTAButton.ButtonType
    let style: CTAButton.Style
    let height: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let colors = getColors(type: type, isEnabled: isEnabled, isPressed: isPressed)
        
        Group {
            if style == .rounded {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.background)
            } else {
                Rectangle()
                    .fill(colors.background)
            }
        }
        .overlay(
            configuration.label
                .foregroundStyle(colors.foreground)
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private func getColors(type: CTAButton.ButtonType, isEnabled: Bool, isPressed: Bool) -> (background: Color, foreground: Color) {
        // ... (색상 관련 로직은 변경 없음)
        switch type {
        case .dark:
            if isPressed {
                return (Color.component.cta.dark.pressedBg, Color.component.cta.dark.text)
            } else if !isEnabled {
                return (Color.component.cta.dark.disabledBg, Color.component.cta.dark.disabledText)
            } else {
                return (Color.component.cta.dark.bg, Color.component.cta.dark.text)
            }
        case .blue:
            if isPressed {
                return (Color.component.cta.primary.pressedBg, Color.component.cta.primary.text)
            } else if !isEnabled {
                return (Color.component.cta.primary.disabledBg, Color.component.cta.primary.disabledText)
            } else {
                return (Color.component.cta.primary.bg, Color.component.cta.primary.text)
            }
        case .text:
            if isPressed {
                return (Color.component.cta.transparentText.pressedBg, Color.component.cta.transparentText.text)
            } else if !isEnabled {
                return (Color.clear, Color.component.cta.transparentText.disabledText)
            } else {
                return (Color.clear, Color.component.cta.transparentText.text)
            }
        }
    }
}

// MARK: - Preview
#Preview("CTAButton") {
    VStack(spacing: 20) {
        // --- Rounded (기본) ---
        CTAButton(title: "라운드 버튼 (기본 높이)", type: .blue, action: {})
        CTAButton(title: "라운드 버튼 (높이 56)", type: .dark, height: 56, action: {})
        
        // --- Keypad (새로운 스타일) ---
        CTAButton(title: "키패드 버튼 (기본 높이)", type: .blue, style: .keypad, action: {})
        CTAButton(title: "키패드 버튼 (높이 51)", type: .blue, style: .keypad, height: 51, action: {})
        
        // --- Disabled ---
        CTAButton(title: "비활성화", type: .blue, action: {})
            .disabled(true)
    }
    .padding()
}
