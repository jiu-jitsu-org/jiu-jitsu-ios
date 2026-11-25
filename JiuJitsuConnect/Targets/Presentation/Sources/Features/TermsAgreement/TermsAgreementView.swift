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
        static let noticeTopPadding: CGFloat = 12
        /// 안내는 늘 두 줄로 끊어 둔다. 기기 폭에 따라 줄 수가 바뀌면 시트 높이 계산이 어긋난다.
        static let noticeHeight: CGFloat = 52
    }

    /// 가입 안내 한 줄이 시트에 더하는 높이(#380). 시트 높이를 정하는 `LoginView`가 쓴다.
    static let signupNoticeBlockHeight: CGFloat = Metrics.noticeTopPadding + Metrics.noticeHeight
    
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

            signupNotice
                .padding(.horizontal, 20)
                .padding(.top, Metrics.noticeTopPadding)
            
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

    // MARK: - 가입 안내 (#380)
    /// 같은 사람도 소셜마다 다른 계정이라, 다른 버튼을 눌러 여기까지 왔다면 새 계정이 생긴다는 것을 동의 전에 알린다.
    private var signupNotice: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(noticeLines, id: \.self) { line in
                Text(line)
            }
        }
        .font(Font.pretendard.captionM)
        .foregroundStyle(Color.semantic.text.secondary)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Metrics.noticeHeight)
        .background(Color.semantic.surface.secondary, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private var noticeLines: [String] {
        guard let provider = store.recentOtherProvider else {
            return ["예전에 다른 방법으로 가입했다면", "그 방법으로 로그인해 주세요"]
        }
        let name = provider.displayName
        return ["최근엔 \(name)로 로그인했어요", "같은 계정을 쓰려면 \(name)로 로그인해 주세요"]
    }
}

#Preview("약관 시트 — 일반 안내") {
    TermsAgreementView(store: Store(initialState: TermsAgreementFeature.State()) {
        TermsAgreementFeature()
    })
}

#Preview("약관 시트 — 최근 로그인 수단 안내") {
    TermsAgreementView(store: Store(initialState: TermsAgreementFeature.State(recentOtherProvider: .kakao)) {
        TermsAgreementFeature()
    })
}
