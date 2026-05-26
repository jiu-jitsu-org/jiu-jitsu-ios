//
//  BeltSettingView.swift
//  Presentation
//
//  Created by suni on 1/26/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

public struct BeltSettingView: View {

    /// 바텀 시트 detent에 사용되는 본문 콘텐츠의 고정 높이 (safe area 미포함)
    /// 24(handle) + 48(title) +16+ 28+109+28(picker) + 8+51+24(CTA) = 362
    public static let contentHeight: CGFloat = 336

    @Bindable var store: StoreOf<BeltSettingFeature>

    public init(store: StoreOf<BeltSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            pickerSection
            confirmButton
        }
        // body 내재 높이 = detent (= contentHeight) > 시트 내부 가용 영역(detent - safe area)
        // 이면 VStack이 safe area 안쪽으로 자연스럽게 오버플로우해서 body 바닥이
        // 디바이스 바닥에 닿게 된다. 그 결과 CTA는 `.padding(.bottom, 24)`만큼만
        // 디바이스 바닥에서 떨어진 위치에 정확히 부착된다.
        // `.ignoresSafeArea(.container, edges: .bottom)`를 명시하면 iOS 26 시트가
        // 별도 내부 inset을 끼워 넣어 오히려 CTA가 더 위로 밀려나므로 사용하지 않는다.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
    }
    
    // MARK: - View Components
    
    private var handleBar: some View {
        ZStack {
            Capsule()
                .fill(Color.component.bottomSheet.selected.container.handle)
                .frame(width: 48, height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
    }
    
    private var titleSection: some View {
        VStack {
            Spacer()
            Text("벨트")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 20)
    }
    
    private var pickerSection: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // 벨트 색상 피커
            SheetPickerView(
                items: Array(BeltRank.allCases.reversed()),
                selectedItem: store.selectedRank,
                displayText: { $0.displayName },
                onSelect: { rank in
                    store.send(.view(.rankSelected(rank)))
                }
            )
            
            // 벨트 그랄 피커
            SheetPickerView(
                items: Array(BeltStripe.allCases.reversed()),
                selectedItem: store.selectedStripe,
                displayText: { $0.displayName },
                onSelect: { stripe in
                    store.send(.view(.stripeSelected(stripe)))
                }
            )
            
            Spacer()
        }
        // SheetPickerView 실제 높이가 151pt(45*3 + 8*2)라서 상하 28pt 패딩(=56pt)을
        // 그대로 두면 본문이 contentHeight(336)를 넘어 핸들이 클립된다.
        // 디자인상 picker section(여백 포함) 높이 165pt(=28+109+28) 유지를 위해
        // 165 - 151 = 14pt → 위아래 7pt씩으로 보정.
        .padding(.vertical, 7)
        .padding(.top, 16)
    }
    
    private var confirmButton: some View {
        CTAButton(
            title: store.isInitialSetup ? "체급도 입력하기" : "확인",
            action: {
                store.send(.view(.confirmButtonTapped))
            }
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    BeltSettingView(
        store: Store(
            initialState: BeltSettingFeature.State()
        ) {
            BeltSettingFeature()
        }
    )
}
