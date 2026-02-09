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
    
    // 성별 아이템 (여성 → 남성)
    private let genderItems = [
        GenderItem(gender: .female),
        GenderItem(gender: .male)
    ]
    
    // 체중 정수 부분 (150~40, 큰 수부터)
    private let integerWeights = (40...150).reversed().map { WeightComponent(value: $0) }
    
    // 체중 소수 부분 (9 → 0, 0.1 단위)
    private let decimalWeights = (0...9).reversed().map { WeightComponent(value: $0) }
    
    public init(store: StoreOf<WeightClassSettingFeature>) {
        self.store = store
    }
    
    // 현재 선택된 체중의 정수 부분
    private var selectedInteger: Int {
        Int(store.selectedWeightKg)
    }
    
    // 현재 선택된 체중의 소수 부분 (0~9)
    private var selectedDecimal: Int {
        let decimal = store.selectedWeightKg - Double(selectedInteger)
        return Int(round(decimal * 10))
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
        HStack(alignment: .top) {
            Text("체급")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
            
            Spacer()
            
            // 체급 숨기기 토글
            HStack(alignment: .center, spacing: 8) {
                Text("체급 숨기기 켜짐")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                
                Toggle("", isOn: $store.isWeightHidden.sending(\.view.weightHiddenToggled))
                    .labelsHidden()
                    .tint(Color.component.switch.on.bg)
            }
            .frame(height: 28)
        }
        .frame(height: 28)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    private var pickerSection: some View {
        HStack(spacing: 24) {
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
            
            HStack(spacing: 8) {
                // 체중 정수 부분 피커
                SheetPickerView(
                    items: integerWeights,
                    selectedItem: integerWeights.first(where: { $0.value == selectedInteger }) ?? integerWeights[20],
                    displayText: { "\($0.value)" },
                    width: 72,
                    onSelect: { item in
                        let newWeight = Double(item.value) + Double(selectedDecimal) / 10.0
                        let roundedWeight = round(newWeight * 10) / 10.0
                        store.send(.view(.weightChanged(roundedWeight)))
                    }
                )
                
                // 소수점
                VStack(alignment: .center) {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.component.picker.unit)
                        .frame(width: 6, height: 6)
                        .padding(.bottom, 6)
                }
                .frame(width: 10, height: 56)
                
                // 체중 소수 부분 피커
                SheetPickerView(
                    items: decimalWeights,
                    selectedItem: decimalWeights.first(where: { $0.value == selectedDecimal }) ?? decimalWeights[0],
                    displayText: { "\($0.value)" },
                    width: 72,
                    onSelect: { item in
                        let newWeight = Double(selectedInteger) + Double(item.value) / 10.0
                        let roundedWeight = round(newWeight * 10) / 10.0
                        store.send(.view(.weightChanged(roundedWeight)))
                    }
                )
                
                // kg 단위
                Text("kg")
                    .font(Font.pretendard.custom(weight: .medium, size: 24))
                    .foregroundStyle(Color.component.picker.itemSelectedText)
            }
            
            Spacer()
        }
        .padding(.vertical, 28)
        .padding(.top, 16)
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

#Preview("기본 상태") {
    WeightClassSettingView(
        store: Store(
            initialState: WeightClassSettingFeature.State()
        ) {
            WeightClassSettingFeature()
        }
    )
}
#Preview("여성 선택, 체급 숨김") {
    WeightClassSettingView(
        store: Store(
            initialState: WeightClassSettingFeature.State(
                selectedGender: .female,
                selectedWeightKg: 55.5,
                isWeightHidden: true
            )
        ) {
            WeightClassSettingFeature()
        }
    )
}

#Preview("남성, 무거운 체급") {
    WeightClassSettingView(
        store: Store(
            initialState: WeightClassSettingFeature.State(
                selectedGender: .male,
                selectedWeightKg: 120.5,
                isWeightHidden: false
            )
        ) {
            WeightClassSettingFeature()
        }
    )
}
