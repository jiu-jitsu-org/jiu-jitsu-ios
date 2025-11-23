//
//  SettingsFeature.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import ComposableArchitecture
import Foundation
import Domain

@Reducer
public struct SettingsFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        let authInfo: AuthInfo
        var appVersion: String
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                self.appVersion = version
            } else {
                self.appVersion = "N/A"
            }
        }
    }
    
    @CasePathable
    public enum Action: Equatable {
        case backButtonTapped
        case termsButtonTapped
        case privacyPolicyButtonTapped
        case logoutButtonTapped
        case withdrawalButtonTapped

    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
}
