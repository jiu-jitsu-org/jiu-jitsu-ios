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
    
    public init(state: ToastState, onSwipe: @escaping () -> Void, onButtonTapped: @escaping (ToastState.Action) -> Void, hasBottomNavBar: Bool) {
        self.state = state
        self.onSwipe = onSwipe
        self.onButtonTapped = onButtonTapped
        self.hasBottomNavBar = hasBottomNavBar
    }
    
    let state: ToastState
    var onSwipe: () -> Void
    var onButtonTapped: (ToastState.Action) -> Void
    
    // BNB 유무에 따라 위치를 조정하기 위한 파라미터
    let hasBottomNavBar: Bool
    
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
        .padding(.horizontal, 24)
        .padding(.bottom, hasBottomNavBar ? 80 : 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

// MARK: - 수정된 Preview
#Preview("Toast Previews") {
    struct ToastPreviewContainer: View {
        @State private var currentToast: ToastState?
        @State private var showToast = false
        
        var body: some View {
            ZStack {
                // 배경
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Toast Preview")
                        .font(.largeTitle.bold())
                        .padding(.top, 50)
                    
                    VStack(spacing: 16) {
                        // Simple Toast
                        Button("Show Simple Toast") {
                            showToast(
                                ToastState(message: "파일이 성공적으로 저장되었습니다.", style: .info)
                            )
                        }
                        .buttonStyle(PreviewButtonStyle())
                        
                        // Action Toast
                        Button("Show Action Toast") {
                            showToast(
                                ToastState(message: "연결이 끊어졌습니다.", style: .action(title: "확인", action: .done))
                            )
                        }
                        .buttonStyle(PreviewButtonStyle())
                        
                        // Long Message Toast
                        Button("Show Long Message Toast") {
                            showToast(
                                ToastState(
                                    message: "네트워크 연결에 문제가 발생했습니다. 인터넷 연결을 확인해주세요.",
                                    style: .action(title: "확인", action: .done)
                                )
                            )
                        }
                        .buttonStyle(PreviewButtonStyle())
                        
                        // 현재 상태 표시 (디버깅용)
                        Text("Toast Visible: \(showToast ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // 시뮬레이션을 위한 하단 네비게이션 바
                    Rectangle()
                        .fill(.white)
                        .frame(height: 80)
                        .overlay(
                            Text("Bottom Navigation Bar")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        )
                }
            }
            .overlay(alignment: .bottom) {
                // Toast Overlay - 조건 단순화
                if showToast, let toast = currentToast {
                    ToastView(
                        state: toast,
                        onSwipe: {
                            dismissToast()
                        },
                        onButtonTapped: { action in
                            Log.trace("Button tapped: \(action.description)", category: .view, level: .debug)
                            dismissToast()
                        },
                        hasBottomNavBar: true
                    )
                    .zIndex(999)
                    .allowsHitTesting(true)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showToast)
        }
        
        private func showToast(_ toast: ToastState) {
            currentToast = toast
            showToast = true
            
            // 3초 후 자동 dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if showToast {
                    dismissToast()
                }
            }
        }
        
        private func dismissToast() {
            showToast = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentToast = nil
            }
        }
    }
    
    return ToastPreviewContainer()
}

// MARK: - Preview Helper Styles
struct PreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                configuration.isPressed ?
                Color.blue.opacity(0.8) : Color.blue
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
