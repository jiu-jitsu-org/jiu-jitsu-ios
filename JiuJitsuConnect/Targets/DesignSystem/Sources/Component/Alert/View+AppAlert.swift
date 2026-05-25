//
//  View+AppAlertStyle.swift
//  DesignSystem
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - View Modifier for Presentation
struct AppAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let alert: AppAlertView

    func body(content: Content) -> some View {
        content
            .overlay {
                // transition을 alert 자체에 묶고 animation은 isPresented 변경에만 한정한다.
                // ZStack 전체에 .animation을 걸면 마운트 직후 내부 버튼의 layout pass(콘텐츠 너비 → maxWidth 확장)까지
                // implicit animation 대상이 되어 "버튼이 길었다가 줄어드는" 잔상이 보였다.
                if isPresented {
                    alert
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

public extension View {
    func appAlert(isPresented: Binding<Bool>, configuration: AppAlertConfiguration) -> some View {
        self.modifier(
            AppAlertModifier(isPresented: isPresented, alert: AppAlertView(configuration: configuration, isPresented: isPresented))
        )
    }
}
