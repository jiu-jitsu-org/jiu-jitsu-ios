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

    func body(content: Content) -> some View {
        ZStack {
            content // 원래의 View

            if isPresented {
                // 뒷배경 어둡게 처리
                Color.component.bottomSheet.selected.container.scrim
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false // 배경 탭하면 닫기
                    }
                
                // 바텀시트
                VStack(spacing: 0) {
                    Spacer()
                    
                    TermsAgreementSheetView(
                        title: title,
                        items: $items,
                        buttonTitle: buttonTitle,
                        onButtonTapped: onButtonTapped,
                        onRowTapped: onRowTapped
                    )
                    .background(Color.component.bottomSheet.selected.container.background)
                    .ignoresSafeArea(edges: .bottom) // 바텀시트 자체는 하단 안전 영역을 무시
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
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
