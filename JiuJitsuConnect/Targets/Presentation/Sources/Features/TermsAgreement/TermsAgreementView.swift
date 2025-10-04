//
//  TermsAgreementView.swift
//  Presentation
//
//  Created by suni on 10/3/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct TermsAgreementView: View {
    
    @Bindable var store: StoreOf<TermsAgreementFeature>

    public init(store: StoreOf<TermsAgreementFeature>) {
        self.store = store
    }
    
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
            Text("최소한의 정보만 받을게요")
                .font(Font.pretendard.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // 동의 항목 리스트
            VStack(spacing: 4) {
                ForEachStore(
                    self.store.scope(state: \.rows, action: \.rows)
                ) { rowStore in
                    TermsAgreementRowView(store: rowStore)
                        .frame(height: 40)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // TODO: - 공통 CTA 컴포넌트로 변경
            // 메인 액션 버튼
            Button(action: { store.send(.allAgreeButtonTapped) }) {
                Text("모두 동의하기")
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
        )
    }
}
