//
//  View+BottomSheet.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

import SwiftUI

// MARK: - ViewModifier로 쉽게 사용하기
struct TermsAgreementSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    // 바텀시트에 필요한 모든 데이터를 전달받습니다.
    let title: String
    @Binding var items: [TermsAgreementSheetItem]
    let buttonTitle: String
    let onButtonTapped: () -> Void
    let onRowTapped: (UUID) -> Void
    
    // MARK: - 제스처 상태를 위한 프로퍼티
    @State private var sheetOffset: CGFloat = 0
    @State private var isDragging = false
    
    // 드래그가 끝나고 시트가 닫힐 임계값 (threshold)
    private let dismissThreshold: CGFloat = 100
    
    // 위로 올라갈 수 있는 최대 높이 (음수 값)
    private let maxUpwardOffset: CGFloat = -30 // 이 값을 조정하면 올라가는 높이 제한
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
                    TermsAgreementSheetView(
                        title: title,
                        items: $items,
                        buttonTitle: buttonTitle,
                        onButtonTapped: onButtonTapped,
                        onRowTapped: onRowTapped
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .background(
                        Color.component.bottomSheet.selected.container.background
                    )
                    .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .offset(y: sheetOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let translationHeight = value.translation.height
                                
                                if translationHeight > 0 { // 아래로 드래그
                                    sheetOffset = translationHeight
                                } else { // 위로 드래그 (저항감)
                                    let calculatedOffset = translationHeight / 5.0 // 저항값 단순화
                                    sheetOffset = max(maxUpwardOffset, calculatedOffset)
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                if value.translation.height > dismissThreshold {
                                    dismiss()
                                } else {
                                    withAnimation(.spring()) {
                                        sheetOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        }
    }
    
    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        // 애니메이션이 끝난 후 offset을 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sheetOffset = 0
        }
    }
}

public extension View {
    func bottomSheet(
        isPresented: Binding<Bool>,
        title: String,
        items: Binding<[TermsAgreementSheetItem]>,
        buttonTitle: String,
        onButtonTapped: @escaping () -> Void,
        onRowTapped: @escaping (UUID) -> Void
    ) -> some View {
        self.modifier(
            TermsAgreementSheetModifier(
                isPresented: isPresented,
                title: title,
                items: items,
                buttonTitle: buttonTitle,
                onButtonTapped: onButtonTapped,
                onRowTapped: onRowTapped
            )
        )
    }
}
