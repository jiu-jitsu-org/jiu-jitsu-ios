//
//  View+BottomSheet.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

 import SwiftUI

// FIXME: - 커스텀 바텀 시트 UX
private enum SheetConstants {
    static let dismissThreshold: CGFloat = 100 // 드래그가 끝나고 시트가 닫힐 임계값 (threshold)
    static let maxUpwardHeight: CGFloat = 50 // 위로 늘어날 수 있는 최대 높이
    static let baseResistance: CGFloat = 3.0
    static let resistanceScale: CGFloat = 150.0
}

// MARK: - ViewModifier로 쉽게 사용하기
private struct CustomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    
    @ViewBuilder let sheetContent: () -> SheetContent

    // MARK: - 제스처 상태를 위한 프로퍼티
    @State private var sheetOffset: CGFloat = 0       // 시트 전체의 Y축 위치
    @State private var additionalHeight: CGFloat = 0  // 스트레칭 배경의 추가 높이
    @State private var isDragging = false
    
    init(isPresented: Binding<Bool>, @ViewBuilder sheetContent: @escaping () -> SheetContent) {
        self._isPresented = isPresented
        self.sheetContent = sheetContent
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                content // 원래의 View
                
                if isPresented {
                    // 뒷배경 어둡게 처리
                    Color.component.bottomSheet.selected.container.scrim
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismiss()
                        }
                    
                    // --- 바텀시트 UI ---
                    // 1. 위치를 잡기 위한 최상위 컨테이너 VStack
                    VStack(spacing: 0) {
                        Spacer() // 바텀시트를 화면 하단으로 밀어냄
                        
                        VStack(spacing: 0) {
                            sheetContent()
                            
                            Rectangle()
                                .fill(Color.component.bottomSheet.selected.container.background)
                                .frame(height: geometry.safeAreaInsets.bottom + additionalHeight)
                        }
                        .background(Color.component.bottomSheet.selected.container.background) // 전체 배경 추가
                        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                        .offset(y: sheetOffset)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                self.handleDragChange(value.translation.height)
                            }
                            .onEnded { _ in
                                isDragging = false
                                // offset 기준으로 닫힘 여부 판단
                                if sheetOffset > SheetConstants.dismissThreshold {
                                    dismiss()
                                } else {
                                    // 모든 경우에 원래 상태로 복귀
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        additionalHeight = 0
                                        sheetOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea()
            .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        }
    }
    
    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            additionalHeight = 0
        }
    }
    
    private func handleDragChange(_ translationHeight: CGFloat) {
        if translationHeight < 0 { // 위로 드래그 (스트레칭)
             let dragDistance = abs(translationHeight)
             // 2. 드래그 거리에 비례한 추가 저항 계산
            let additionalResistance = dragDistance / SheetConstants.resistanceScale
             // 3. 최종 저항값
            let totalResistance = SheetConstants.baseResistance + additionalResistance
             
             let resistedHeight = dragDistance / totalResistance
             
            additionalHeight = min(resistedHeight, SheetConstants.maxUpwardHeight)
             sheetOffset = 0 // 위로 드래그 시에는 offset 고정
            
        } else { // 아래로 드래그 (닫기)
            if additionalHeight > 0 {
                // 1. 스트레칭 된 높이가 있다면 먼저 줄입니다.
                additionalHeight = max(0, -translationHeight)
                sheetOffset = 0
            } else {
                // 2. 스트레칭 높이가 0이 되면, 그때부터 시트 전체를 내립니다.
                sheetOffset = translationHeight
            }
        }
        
    }
 }

public extension View {
    func customBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(
            CustomSheetModifier(
                isPresented: isPresented,
                sheetContent: content
            )
        )
    }
}
