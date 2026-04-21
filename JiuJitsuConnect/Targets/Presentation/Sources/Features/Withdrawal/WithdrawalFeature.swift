//
//  WithdrawalFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct WithdrawalFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    public enum Action: Sendable {
        case backButtonTapped
    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
                // MARK: UI Actions
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            }
        }
    }
}
