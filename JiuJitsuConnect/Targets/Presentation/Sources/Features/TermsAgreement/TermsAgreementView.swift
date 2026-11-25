//
//  TermsAgreementView.swift
//  Presentation
//
//  Created by suni on 10/3/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

public struct TermsAgreementView: View {

    private enum Metrics {
        static let noticeTopPadding: CGFloat = 8
        /// 한 줄 고정. 시트 높이를 미리 계산하므로 줄 수가 바뀌면 안 된다.
        static let noticeHeight: CGFloat = 20
    }

    /// 최근 로그인 안내 한 줄이 시트에 더하는 높이(#380). 안내가 있을 때만 `LoginView`가 시트 높이에 더한다.
    static let recentLoginNoticeBlockHeight: CGFloat = Metrics.noticeTopPadding + Metrics.noticeHeight

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

            if let provider = store.recentOtherProvider {
                recentLoginNotice(provider)
                    .padding(.horizontal, 20)
                    .padding(.top, Metrics.noticeTopPadding)
            }
            
            // 동의 항목 리스트
            VStack(spacing: 4) {
                ForEach(
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
            CTAButton(title: store.buttonTitle, action: {
                store.send(.view(.mainButtonTapped))
            })
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
        }
        .background(
            Color.component.bottomSheet.selected.container.background
        )
        .fullScreenCover(
            item: $store.scope(state: \.termsWebCover, action: \.termsWebCover)
        ) { termsStore in
            TermsWebViewView(store: termsStore)
        }
    }

    // MARK: - 최근 로그인 안내 (#380)
    /// 같은 사람도 소셜마다 다른 계정이라, 이 기기에서 다른 수단으로 로그인했었다면 동의 전에 짚어 준다.
    /// 처음 가입하는 사람에겐 잡음이라 기록이 없거나 같은 수단이면 보이지 않는다.
    private func recentLoginNotice(_ provider: SNSProvider) -> some View {
        HStack(spacing: 4) {
            // 경고 노랑은 아직 토스트 토큰에만 있다(semantic 토큰이 생기면 바꾼다)
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(Color.component.toast.icon.warning)
                .accessibilityLabel("주의")
            Text("예전엔 \(provider.displayName)로 로그인했어요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.semantic.text.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Metrics.noticeHeight)
        .accessibilityElement(children: .combine)
    }
}

#Preview("약관 시트 — 안내 없음") {
    TermsAgreementView(store: Store(initialState: TermsAgreementFeature.State()) {
        TermsAgreementFeature()
    })
}

#Preview("약관 시트 — 예전 로그인 수단 안내") {
    TermsAgreementView(store: Store(initialState: TermsAgreementFeature.State(recentOtherProvider: .kakao)) {
        TermsAgreementFeature()
    })
}
