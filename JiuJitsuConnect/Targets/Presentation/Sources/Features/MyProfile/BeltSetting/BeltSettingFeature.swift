//
//  BeltSettingFeature.swift
//  Presentation
//
//  Created by suni on 1/26/26.
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit

@Reducer
public struct BeltSettingFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Sendable {
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
            /// 등록·수정 모두 벨트 정보를 저장하고 완료 (프로필 체급은 받지 않는다, #188)
            case didConfirmBelt(rank: BeltRank, stripe: BeltStripe)
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.rankSelected(let rank)):
                // 이미 선택된 값과 동일하면 무시 (스크롤 애니메이션 중 중복 호출 방지)
                guard state.selectedRank != rank else { return .none }
                Log.trace("벨트 등급 선택됨: \(rank.displayName)", category: .debug, level: .info)
                state.selectedRank = rank
                return .none
                
            case .view(.stripeSelected(let stripe)):
                // 이미 선택된 값과 동일하면 무시 (스크롤 애니메이션 중 중복 호출 방지)
                guard state.selectedStripe != stripe else { return .none }
                Log.trace("벨트 띠 선택됨: \(stripe.displayName)", category: .debug, level: .info)
                state.selectedStripe = stripe
                return .none
                
            case .view(.confirmButtonTapped):
                Log.trace("확인 버튼 탭됨 - selectedRank: \(state.selectedRank.displayName), selectedStripe: \(state.selectedStripe.displayName)", category: .debug, level: .info)
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
