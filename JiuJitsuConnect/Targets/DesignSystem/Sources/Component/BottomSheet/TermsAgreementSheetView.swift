//
//  TermsAgreementSheet.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

import SwiftUI

// MARK: - 메인 바텀시트 View
public struct TermsAgreementSheetView: View {
    // MARK: - Properties
    let title: String
    @Binding var items: [TermsAgreementSheetItem]
    let buttonTitle: String
    
    // 외부(Feature)로 Action을 전달하기 위한 클로저
    let onButtonTapped: () -> Void
    let onRowTapped: (UUID) -> Void
    
    public init(
        title: String,
        items: Binding<[TermsAgreementSheetItem]>,
        buttonTitle: String,
        onButtonTapped: @escaping () -> Void,
        onRowTapped: @escaping (UUID) -> Void
    ) {
        self.title = title
        self._items = items
        self.buttonTitle = buttonTitle
        self.onButtonTapped = onButtonTapped
        self.onRowTapped = onRowTapped
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            // 상단 핸들
            ZStack {
                Capsule()
                    .fill(Color.component.bottomSheet.selected.container.handle)
                    .frame(width: 40, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            
            // 타이틀
            Text(title)
                .font(Font.pretendard.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // 동의 항목 리스트
            VStack(spacing: 4) {
                ForEach($items) { $item in
                    TermsAgreementSheetRowView(item: $item, onRowTapped: onRowTapped)
                        .frame(height: 40)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // TODO: - 공통 CTA 컴포넌트로 변경
            // 메인 액션 버튼
            Button(action: onButtonTapped) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(
            Color.component.bottomSheet.selected.container.background
                .clipShape(.rect(
                    topLeadingRadius: 24,
                    topTrailingRadius: 24
                ))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Preview

 #Preview("Terms Agreement Sheet") {
    // Preview를 위한 간단한 컨테이너 View
    struct BottomSheetPreviewContainer: View {
        // 바텀시트 표시 여부를 제어하는 State
        @State private var isPresented = true
        
        // 바텀시트에 표시될 Mock 데이터
        @State private var items: [TermsAgreementSheetItem] = [
            .init(title: "서비스 이용약관 동의", isChecked: true, type: .required),
            .init(title: "개인정보 처리방침 동의", isChecked: true, type: .required),
            .init(title: "만 14세 이상입니다.", isChecked: false, type: .required),
            .init(title: "마케팅 정보 수신", isChecked: false, type: .optional)
        ]
        
        var body: some View {
            // 바텀시트가 올라올 메인 화면 (임시)
            ZStack {
                Color.blue.ignoresSafeArea()
                
                Button("바텀시트 열기") {
                    isPresented = true
                }
            }
            .bottomSheet(
                isPresented: $isPresented,
                title: "최소한의 정보만 받을게요",
                items: $items,
                buttonTitle: "모두 동의하기",
                onButtonTapped: {
                    print("모두 동의하기 버튼 탭")
                    isPresented = false
                },
                onRowTapped: { id in
                    print("상세보기 탭: \(id)")
                }
            )
        }
    }
    
    // 컨테이너 View를 반환하여 Preview를 생성합니다.
    return BottomSheetPreviewContainer()
 }
