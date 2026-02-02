//
//  WeightClassSettingView.swift
//  Presentation
//
//  Created by suni on 2/3/26.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture
import Domain

// MARK: - Gender Wrapper (SheetPickerView용)
struct GenderItem: Identifiable, Hashable {
    let gender: Gender
    var id: String { gender.rawValue }
    var displayName: String { gender.displayName }
}

// MARK: - Weight Component Wrapper (정수/소수 부분 분리)
struct WeightComponent: Identifiable, Hashable {
    let value: Int
    var id: Int { value }
}

public struct WeightClassSettingView: View {
    @Bindable var store: StoreOf<WeightClassSettingFeature>
    
    // 성별 아이템
    private let genderItems = [
        GenderItem(gender: .male),
        GenderItem(gender: .female)
    ]
    
    // 체중 정수 부분 (40~150)
    private let integerWeights = (40...150).map { WeightComponent(value: $0) }
    
    // 체중 소수 부분 (0, 5 → 0.0, 0.5)
    private let decimalWeights = [
        WeightComponent(value: 0),
        WeightComponent(value: 5)
    ]
    
    public init(store: StoreOf<WeightClassSettingFeature>) {
        self.store = store
    }
    
    // 현재 선택된 체중의 정수 부분
    private var selectedInteger: Int {
        Int(store.selectedWeightKg)
    }
    
    // 현재 선택된 체중의 소수 부분 (0 또는 5)
    private var selectedDecimal: Int {
        let decimal = store.selectedWeightKg - Double(selectedInteger)
        return decimal >= 0.25 ? 5 : 0
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleAndToggleSection
            pickerSection
            confirmButton
        }
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
    
    private var titleAndToggleSection: some View {
        HStack(alignment: .center) {
            Text("체급")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
            
            Spacer()
            
            // 체급 숨기기 토글
            HStack(spacing: 8) {
                Text("체급 숨기기 켜짐")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                
                Toggle("", isOn: $store.isWeightHidden.sending(\.view.weightHiddenToggled))
                    .labelsHidden()
                    .tint(Color.component.cta.primary.bg)
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
    }
    
    private var pickerSection: some View {
        HStack(spacing: 16) {
            Spacer()
            
            // 성별 피커
            SheetPickerView(
                items: genderItems,
                selectedItem: genderItems.first(where: { $0.gender == store.selectedGender }) ?? genderItems[0],
                displayText: { $0.displayName },
                width: 90,
                onSelect: { item in
                    store.send(.view(.genderSelected(item.gender)))
                }
            )
            
            // 체중 정수 부분 피커
            SheetPickerView(
                items: integerWeights,
                selectedItem: integerWeights.first(where: { $0.value == selectedInteger }) ?? integerWeights[20],
                displayText: { "\($0.value)" },
                width: 70,
                onSelect: { item in
                    let newWeight = Double(item.value) + Double(selectedDecimal) / 10.0
                    store.send(.view(.weightChanged(newWeight)))
                }
            )
            
            // 소수점
            Text(".")
                .font(Font.pretendard.custom(weight: .medium, size: 24))
                .foregroundStyle(Color.component.picker.itemSelectedText)
                .offset(y: -8)
            
            // 체중 소수 부분 피커
            SheetPickerView(
                items: decimalWeights,
                selectedItem: decimalWeights.first(where: { $0.value == selectedDecimal }) ?? decimalWeights[0],
                displayText: { "\($0.value)" },
                width: 70,
                onSelect: { item in
                    let newWeight = Double(selectedInteger) + Double(item.value) / 10.0
                    store.send(.view(.weightChanged(newWeight)))
                }
            )
            
            // kg 단위
            Text("kg")
                .font(Font.pretendard.custom(weight: .medium, size: 24))
                .foregroundStyle(Color.component.picker.itemSelectedText)
                .offset(y: -8)
            
            Spacer()
        }
        .padding(.vertical, 28)
    }
    
    private var confirmButton: some View {
        CTAButton(title: "완료", action: {
            store.send(.view(.confirmButtonTapped))
        })
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

#Preview {
    WeightClassSettingView(
        store: Store(
            initialState: WeightClassSettingFeature.State()
        ) {
            WeightClassSettingFeature()
        }
    )
}
