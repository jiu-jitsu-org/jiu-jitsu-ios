//
//  WeightClassSettingFeature.swift
//  Presentation
//
//  Created by suni on 2/3/26.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct WeightClassSettingFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Sendable {
        var selectedGender: Gender
        var selectedWeightKg: Double
        var isWeightHidden: Bool
        
        // 일반적인 체급 범위
        static let weightRange: ClosedRange<Double> = 40.0...150.0
        
        public init(
            selectedGender: Gender = .male,
            selectedWeightKg: Double = 60.0,
            isWeightHidden: Bool = false
        ) {
            self.selectedGender = selectedGender
            self.selectedWeightKg = selectedWeightKg
            self.isWeightHidden = isWeightHidden
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        
        @CasePathable
        public enum ViewAction: Sendable {
            case genderSelected(Gender)
            case weightChanged(Double)
            case weightHiddenToggled(Bool)
            case confirmButtonTapped
        }
        
        @CasePathable
        public enum DelegateAction: Sendable {
            case didConfirmWeightClass(gender: Gender, weightKg: Double, isWeightHidden: Bool)
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.genderSelected(let gender)):
                state.selectedGender = gender
                return .none
                
            case .view(.weightChanged(let weight)):
                state.selectedWeightKg = weight
                return .none
                
            case .view(.weightHiddenToggled(let isHidden)):
                state.isWeightHidden = isHidden
                return .none
                
            case .view(.confirmButtonTapped):
                return .send(.delegate(.didConfirmWeightClass(
                    gender: state.selectedGender,
                    weightKg: state.selectedWeightKg,
                    isWeightHidden: state.isWeightHidden
                )))
                
            case .delegate:
                return .none
            }
        }
    }
}
