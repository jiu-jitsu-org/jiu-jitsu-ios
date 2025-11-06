//
//  SettingFeature.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct SettingFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        let authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    @CasePathable
    public enum Action: Equatable {

    }
}
