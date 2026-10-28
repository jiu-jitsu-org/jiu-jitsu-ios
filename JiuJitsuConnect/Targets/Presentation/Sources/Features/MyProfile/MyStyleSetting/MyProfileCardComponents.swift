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

/// 벨트 카드 — 벨트와 관장·사범 인증 표시
///
/// 남이 보는 프로필에서 상대를 판단하는 첫 기준이 띠와 관장·사범 여부라 둘을 한 카드에 둔다.
/// 체급은 대회에서만 의미가 있어 이 카드에서 뺐다(#117). 등록 흐름은 여전히 벨트 → 체급 순서다.
public struct BeltCardView: View {
    // MARK: - Properties

    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    /// 관장/사범 인증 완료 여부 — `true`이면 벨트 오른쪽에 인증 뱃지 표시
    let isOwner: Bool

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
        HStack(spacing: 8) {
            BeltSection(
                beltRank: beltRank,
                beltStripe: beltStripe,
                onTapped: onBeltTapped
            )

            if isOwner {
                InstructorBadge()
            }
        }
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

// MARK: - InstructorBadge

/// 관장/사범 인증 뱃지. 역할 값(`OWNER`)이 관장과 사범을 구분하지 않아 문구를 함께 쓴다.
private struct InstructorBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text("관장·사범")
                .font(Font.pretendard.buttonS)
                .foregroundStyle(Color.semantic.primary.primary)
        }
    }
}

// MARK: - Preview

#Preview("BeltCardView - 정보 있음") {
    BeltCardView(
        beltRank: .blue,
        beltStripe: .two,
        isOwner: false,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltCardView - 관장/사범 인증") {
    BeltCardView(
        beltRank: .black,
        beltStripe: .two,
        isOwner: true,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("BeltCardView - 정보 없음") {
    BeltCardView(
        beltRank: nil,
        beltStripe: nil,
        isOwner: false,
        onBeltTapped: { },
        onRegisterTapped: { }
    )
    .background(Color.component.background.default)
}
