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
        
        public init(
            selectedRank: BeltRank = .white,
            selectedStripe: BeltStripe = .none
        ) {
            self.selectedRank = selectedRank
            self.selectedStripe = selectedStripe
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
                return .send(.delegate(.didConfirmBelt(
                    rank: state.selectedRank,
                    stripe: state.selectedStripe
                )))
                
            case .delegate:
                return .none
            }
        }
    }
}
