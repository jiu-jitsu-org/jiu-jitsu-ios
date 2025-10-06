//
//  NicknameSettingFeature.swift
//  Presentation
//
//  Created by suni on 10/6/25.
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit
import OSLog

@Reducer
public struct NicknameSettingFeature {
    
    @ObservableState
    public struct State: Equatable {
     
        // LoginFeature로부터 전달받을 데이터
        let tempToken: String
        let isMarketingAgreed: Bool
        
        public init(tempToken: String, isMarketingAgreed: Bool) {
            self.tempToken = tempToken
            self.isMarketingAgreed = isMarketingAgreed
        }
    }
    
    public enum Action: Equatable {
        
    }
    
    public var body: some ReducerOf<Self> {
        
    }
}
