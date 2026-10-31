//
//  BeltPromptView.swift
//  Presentation
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

/// 벨트 묻기 바텀시트 — MY 벨트 시트와 같은 벨트·그랄 휠에 저장 / 나중에
///
/// 앱은 '띠' 대신 MY와 같은 '벨트'로 부른다. 남의 벨트를 보고 있는 순간이라 "내 벨트도"로 묻는다.
public struct BeltPromptView: View {

    /// 바텀 시트 detent 높이 (safe area 미포함)
    /// 24(handle) + 76(제목·설명) + 16+165(picker) + 8+51+4+44+4(CTA 두 개) = 392
    /// iOS 26 시트는 아래에 홈 인디케이터 여백을 따로 두므로 '나중에' 아래는 거의 비운다.
    public static let contentHeight: CGFloat = 392

    let store: StoreOf<BeltPromptFeature>

    public init(store: StoreOf<BeltPromptFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            pickerSection
            buttons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
    }

    private var handleBar: some View {
        Capsule()
            .fill(Color.component.bottomSheet.selected.container.handle)
            .frame(width: 48, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("내 벨트도 보여 줄까요?")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)

            Text(store.hasSaveError ? "저장하지 못했어요. 다시 눌러 주세요." : "프로필과 글 옆에 함께 보여요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .bottomLeading)
        .padding(.horizontal, 20)
    }

    private var pickerSection: some View {
        HStack(spacing: 24) {
            Spacer()

            SheetPickerView(
                items: Array(BeltRank.allCases.reversed()),
                selectedItem: store.selectedRank,
                displayText: { $0.displayName },
                onSelect: { store.send(.view(.rankSelected($0))) }
            )

            SheetPickerView(
                items: Array(BeltStripe.allCases.reversed()),
                selectedItem: store.selectedStripe,
                displayText: { $0.displayName },
                onSelect: { store.send(.view(.stripeSelected($0))) }
            )

            Spacer()
        }
        // MY 벨트 시트와 같은 보정 — 휠 실제 높이 151 + 위아래 7 = 165
        .padding(.vertical, 7)
        .padding(.top, 16)
    }

    private var buttons: some View {
        VStack(spacing: 4) {
            CTAButton(title: "저장") {
                store.send(.view(.saveTapped))
            }
            .disabled(store.isSaving)

            CTAButton(title: "나중에", type: .text, height: 44) {
                store.send(.view(.laterTapped))
            }
            .disabled(store.isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Preview

#Preview {
    BeltPromptView(
        store: Store(initialState: BeltPromptFeature.State(myProfile: CommunityProfile(nickname: "주짓수 러버"))) {
            BeltPromptFeature()
        }
    )
}
