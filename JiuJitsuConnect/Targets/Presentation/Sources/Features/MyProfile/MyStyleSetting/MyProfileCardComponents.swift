//
//  MyProfileCardComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - BeltCardView

/// 벨트 카드
///
/// 체급은 대회에서만 의미가 있어 이 카드에서 뺐고(#117), 프로필 체급은 더 받지 않는다(#188).
/// 관장·사범 인증 뱃지는 커뮤니티 글처럼 닉네임 옆에 둔다(헤더).
public struct BeltCardView: View {
    // MARK: - Properties

    let beltRank: BeltRank?
    let beltStripe: BeltStripe?

    // 비로그인 MY(#242)는 같은 빈 카드에서 로그인으로 보낸다.
    var registerButtonTitle: String = "벨트 등록하기"
    // 프로필을 받기 전(처음 불러오는 중) · 받지 못함(실패) — 새 회원의 빈 카드와 구분한다(#387).
    var isLoading: Bool = false
    var isFailed: Bool = false
    let onBeltTapped: () -> Void
    let onRegisterTapped: () -> Void
    var onRetryTapped: () -> Void = { }

    // MARK: - Body

    public var body: some View {
        Group {
            if isLoading {
                loadingContent
            } else if isFailed {
                failedContent
            } else if let beltRank {
                // 흰 카드 왼쪽 타일에 작은 띠 그림(#320) — 띠 고르기 칩과 같은 BeltIcon.
                BeltSection(
                    beltRank: beltRank,
                    beltStripe: beltStripe,
                    onTapped: onBeltTapped
                )
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.component.beltCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Loading Content

    /// 띠가 있는 카드(BeltSection)와 같은 자리 · 크기의 회색 자리 표시 — 응답 뒤 카드가 덜 흔들린다.
    private var loadingContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.semantic.surface.disabled)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 8) {
                Capsule()
                    .fill(Color.semantic.surface.disabled)
                    .frame(width: 32, height: 12)
                Capsule()
                    .fill(Color.semantic.surface.disabled)
                    .frame(width: 112, height: 18)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("프로필을 불러오는 중")
    }

    // MARK: - Failed Content

    private var failedContent: some View {
        VStack(spacing: 24) {
            Text("프로필을 불러오지 못했어요")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.beltCard.default.text)
                .padding(.top, 24)

            Button {
                onRetryTapped()
            } label: {
                AppButtonConfiguration(title: "다시 시도", size: .medium)
            }
            .appButtonStyle(.primary, size: .medium, height: 38)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty Content
    
    private var emptyContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                // 벨트 아이콘
                Assets.MyProfile.Icon.beltBlue.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 13)
                    .rotationEffect(.degrees(-6.8))
                    .frame(height: 56)
                
                // 안내 텍스트
                Text("벨트가 어떻게 되세요?")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.beltCard.default.text)
            }
            .padding(.top, 24)
            
            // 등록 버튼
            Button {
                onRegisterTapped()
            } label: {
                AppButtonConfiguration(title: registerButtonTitle, size: .medium)
            }
            .appButtonStyle(.primary, size: .medium, height: 38)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - BeltSection

/// 작은 띠 그림 + 벨트명. 남는 가로 영역까지 누르면 벨트 수정 시트가 열린다.
private struct BeltSection: View {
    let beltRank: BeltRank
    let beltStripe: BeltStripe?
    let onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 띠 그림은 띠 고르기 칩·휠과 같은 부품(DesignSystem BeltIcon)을 쓴다(#320).
            BeltIcon(color: beltRank.selectButtonColor)
                .frame(width: 40, height: 40)
                .background(Color.semantic.surface.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("벨트")
                    .font(Font.pretendard.labelM)
                    .foregroundStyle(Color.component.beltCard.filled.labelText)
                    .lineLimit(1)

                Text([beltRank.displayName, beltStripe?.displayName].compactMap { $0 }.joined(separator: " "))
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.beltCard.filled.contentText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("BeltCardView - 정보 있음") {
    BeltCardView(
        beltRank: .blue,
        beltStripe: .two,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltCardView - 불러오는 중 · 실패") {
    VStack(spacing: 20) {
        BeltCardView(beltRank: nil, beltStripe: nil, isLoading: true, onBeltTapped: { }, onRegisterTapped: { })
        BeltCardView(beltRank: nil, beltStripe: nil, isFailed: true, onBeltTapped: { }, onRegisterTapped: { })
    }
    .background(Color.component.background.default)
}

#Preview("BeltCardView - 정보 없음") {
    BeltCardView(
        beltRank: nil,
        beltStripe: nil,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}
