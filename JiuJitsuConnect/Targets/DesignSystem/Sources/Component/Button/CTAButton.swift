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
///   - type: 버튼의 색상 타입 (.dark, .blue, .text). 기본값은 .blue
///   - action: 버튼을 탭했을 때 실행될 클로저
public struct CTAButton: View {
    let title: String
    let type: ButtonType
    let action: () -> Void
    
    public enum ButtonType {
        case dark
        case blue
        case text
    }
    
    public init(
        title: String,
        type: ButtonType = .blue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard.buttonM)
                .id(title)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
        .buttonStyle(CTAButtonStyle(type: type))
    }
}

/// CTAButton의 실제 스타일을 정의하는 private struct 입니다.
private struct CTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    let type: CTAButton.ButtonType
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let colors = getColors(type: type, isEnabled: isEnabled, isPressed: isPressed)
        
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.background)
            configuration.label
                .foregroundStyle(colors.foreground)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    /// 버튼의 상태와 타입에 맞는 배경/전경 색상 튜플을 반환합니다.
    private func getColors(type: CTAButton.ButtonType, isEnabled: Bool, isPressed: Bool) -> (background: Color, foreground: Color) {
        switch type {
        case .dark:
            if isPressed {
                return (Color.component.cta.dark.pressedBg, Color.component.cta.dark.text) // Pressed 상태
            } else if !isEnabled {
                return (Color.component.cta.dark.disabledBg, Color.component.cta.dark.disabledText) // Disabled 상태
            } else {
                return (Color.component.cta.dark.bg, Color.component.cta.dark.text) // Enabled 상태
            }
        case .blue:
            if isPressed {
                return (Color.component.cta.primary.pressedBg, Color.component.cta.primary.text) // Pressed 상태
            } else if !isEnabled {
                return (Color.component.cta.primary.disabledBg, Color.component.cta.primary.disabledText) // Disabled 상태
            } else {
                return (Color.component.cta.primary.bg, Color.component.cta.primary.text) // Enabled 상태
            }
        case .text:
            if isPressed {
                return (Color.component.cta.transparentText.pressedBg, Color.component.cta.transparentText.text) // Pressed 상태
            } else if !isEnabled {
                return (Color.clear, Color.component.cta.transparentText.disabledText) // Disabled 상태
            } else {
                return (Color.clear, Color.component.cta.transparentText.text) // Enabled 상태
            }
        }
    }
}

// MARK: - Preview
#Preview("CTAButton") {
    VStack(spacing: 20) {
        // --- Blue Type ---
        CTAButton(title: "확인", type: .blue, action: {})
        CTAButton(title: "확인", type: .blue, action: {})
            .disabled(true) // Disabled 상태 테스트
        
        // --- Dark Type ---
        CTAButton(title: "확인", type: .dark, action: {})
        CTAButton(title: "확인", type: .dark, action: {})
            .disabled(true)
        
        // --- Text Type ---
        CTAButton(title: "내 배지 보러가기", type: .text, action: {})
        CTAButton(title: "내 배지 보러가기", type: .text, action: {})
            .disabled(true)
    }
    .padding()
}
