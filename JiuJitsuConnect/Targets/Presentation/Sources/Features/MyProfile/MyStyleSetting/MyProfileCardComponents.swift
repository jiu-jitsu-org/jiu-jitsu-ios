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
/// 체급은 대회에서만 의미가 있어 이 카드에서 뺐다(#117). 등록 흐름은 여전히 벨트 → 체급 순서다.
/// 관장·사범 인증 뱃지는 커뮤니티 글처럼 닉네임 옆에 둔다(헤더).
public struct BeltCardView: View {
    // MARK: - Properties

    let beltRank: BeltRank?
    let beltStripe: BeltStripe?

    let onBeltTapped: () -> Void
    let onRegisterTapped: () -> Void

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            if let beltRank {
                filledContent(beltRank: beltRank)
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

    // MARK: - Filled Content

    private func filledContent(beltRank: BeltRank) -> some View {
        BeltSection(
            beltRank: beltRank,
            beltStripe: beltStripe,
            onTapped: onBeltTapped
        )
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    // MARK: - Empty Content
    
    private var emptyContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                // 아이콘 영역
                HStack(spacing: 5) {
                    // 벨트 아이콘
                    VStack {
                        Assets.MyProfile.Icon.beltBlue.swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 13)
                    .rotationEffect(.degrees(-6.8))
                    
                    // 체급 아이콘
                    VStack {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("??")
                                .font(Font.pretendard.title2)
                                .foregroundStyle(Color.primitive.coolGray.cg700)
                            
                            Text("kg")
                                .font(Font.pretendard.bodyS)
                                .foregroundStyle(Color.primitive.coolGray.cg400)
                        }
                    }
                    .frame(width: 55, height: 42)
                    .background(Color.primitive.coolGray.cg25)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 5)
                    .rotationEffect(.degrees(10.49))
                }
                .frame(height: 56)
                
                // 안내 텍스트
                Text("벨트와 체급이 어떻게 되세요?")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.beltCard.default.text)
            }
            .padding(.top, 24)
            
            // 등록 버튼
            Button {
                onRegisterTapped()
            } label: {
                AppButtonConfiguration(title: "벨트/체급 등록하기", size: .medium)
            }
            .appButtonStyle(.primary, size: .medium, height: 38)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - BeltSection

/// 벨트 아이콘 + 벨트명. 남는 가로 영역까지 누르면 벨트 수정 시트가 열린다.
private struct BeltSection: View {
    let beltRank: BeltRank
    let beltStripe: BeltStripe?
    let onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            beltRank.beltIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("벨트")
                    .font(Font.pretendard.labelM)
                    .foregroundStyle(Color.component.beltCard.filled.labelText)

                Text([beltRank.displayName, beltStripe?.displayName].compactMap { $0 }.joined(separator: " "))
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.beltCard.filled.contentText)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped()
        }
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

#Preview("BeltCardView - 정보 없음") {
    BeltCardView(
        beltRank: nil,
        beltStripe: nil,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}
