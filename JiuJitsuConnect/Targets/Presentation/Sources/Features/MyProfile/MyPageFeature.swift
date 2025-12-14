//
//  MyPageFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct MyPageFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    public enum Action: Equatable, Sendable {
        // View UI Actions
        case gymInfoButtonTapped
        case registerBeltButtonTapped
        case registerStyleButtonTapped
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .gymInfoButtonTapped:
                // 도장 정보 입력 화면 이동 로직
                return .none
            case .registerBeltButtonTapped:
                // 벨트/체급 등록 화면 이동 로직
                return .none
            case .registerStyleButtonTapped:
                // 스타일 등록 화면 이동 로직
                return .none
            }
        }
    }
}
