//
//  ToastView.swift
//  DesignSystem
//
//  Created by suni on 9/22/25.
//

import SwiftUI
import CoreKit
import OSLog

public struct ToastView: View {
    
    public init(state: ToastState,
                onSwipe: @escaping () -> Void,
                onButtonTapped: @escaping (ToastState.Action) -> Void) {
        self.state = state
        self.onSwipe = onSwipe
        self.onButtonTapped = onButtonTapped
    }
    
    let state: ToastState
    var onSwipe: () -> Void
    var onButtonTapped: (ToastState.Action) -> Void
    
    public var body: some View {
        HStack(spacing: 16) {
            Text(state.message)
                .font(.pretendard.bodyS)
                .foregroundStyle(Color.component.toast.default.text)
                .lineLimit(2)
                .lineHeight(7)
            
            Spacer(minLength: 0)

            if case let .action(title, action) = state.style {
                Button(title) {
                    onButtonTapped(action)
                }
                .font(.pretendard.buttonS)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.component.button.neutral.defaultBg)
                .foregroundStyle(Color.component.button.neutral.defaultText)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.component.toast.default.background)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.height > 20 || abs(value.translation.width) > 40 {
                        onSwipe()
                    }
                }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
