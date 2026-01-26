//
//  BeltSettingFeature.swift
//  Presentation
//
//  Created by suni on 1/26/26.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct BeltSettingFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var selectedColor: BeltColor
        var selectedDegree: BeltDegree
        
        public init(
            selectedColor: BeltColor = .white,
            selectedDegree: BeltDegree = .none
        ) {
            self.selectedColor = selectedColor
            self.selectedDegree = selectedDegree
        }
    }
    
    public enum BeltColor: String, CaseIterable, Sendable {
        case white = "화이트"
        case blue = "블루"
        case purple = "퍼플"
        case brown = "브라운"
        case black = "블랙"
        case red = "레드"
    }
    
    public enum BeltDegree: String, CaseIterable, Sendable {
        case none = "무그랄"
        case one = "1그랄"
        case two = "2그랄"
        case three = "3그랄"
        case four = "4그랄"
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Sendable {
            case colorSelected(BeltColor)
            case degreeSelected(BeltDegree)
            case confirmButtonTapped
        }
        
        public enum DelegateAction: Sendable {
            case didConfirmBelt(color: BeltColor, degree: BeltDegree)
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.colorSelected(let color)):
                state.selectedColor = color
                return .none
                
            case .view(.degreeSelected(let degree)):
                state.selectedDegree = degree
                return .none
                
            case .view(.confirmButtonTapped):
                return .send(.delegate(.didConfirmBelt(
                    color: state.selectedColor,
                    degree: state.selectedDegree
                )))
                
            case .delegate:
                return .none
            }
        }
    }
}
