//
//  BeltSettingFeature.swift
//  Presentation
//
//  Created by suni on 1/26/26.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct BeltSettingFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var selectedRank: BeltRank
        var selectedStripe: BeltStripe
        /// 최초 벨트 설정인지 여부 (true면 체급 설정으로 연결, false면 바로 저장)
        var isInitialSetup: Bool
        
        public init(
            selectedRank: BeltRank = .white,
            selectedStripe: BeltStripe = .none,
            isInitialSetup: Bool = false
        ) {
            self.selectedRank = selectedRank
            self.selectedStripe = selectedStripe
            self.isInitialSetup = isInitialSetup
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Sendable {
            case rankSelected(BeltRank)
            case stripeSelected(BeltStripe)
            case confirmButtonTapped
        }
        
        public enum DelegateAction: Sendable {
            /// 최초 설정 시: 벨트 정보를 전달하고 체급 설정 화면으로 이동
            case proceedToWeightClassSetting(rank: BeltRank, stripe: BeltStripe)
            /// 수정 시: 벨트 정보를 저장하고 완료
            case didConfirmBelt(rank: BeltRank, stripe: BeltStripe)
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.rankSelected(let rank)):
                state.selectedRank = rank
                return .none
                
            case .view(.stripeSelected(let stripe)):
                state.selectedStripe = stripe
                return .none
                
            case .view(.confirmButtonTapped):
                if state.isInitialSetup {
                    // 최초 설정: 체급 설정 화면으로 이동
                    return .send(.delegate(.proceedToWeightClassSetting(
                        rank: state.selectedRank,
                        stripe: state.selectedStripe
                    )))
                } else {
                    // 수정: 바로 저장
                    return .send(.delegate(.didConfirmBelt(
                        rank: state.selectedRank,
                        stripe: state.selectedStripe
                    )))
                }
                
            case .delegate:
                return .none
            }
        }
    }
}
