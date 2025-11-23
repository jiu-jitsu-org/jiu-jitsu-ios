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
        
        public enum Alert: Equatable {
            case logout
            case withdrawal
        }
        var alert: Alert? = nil
        
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
        // View UI Actions
        case backButtonTapped
        case termsButtonTapped
        case privacyPolicyButtonTapped
        case logoutButtonTapped
        case withdrawalButtonTapped
        
        // Alert Actions
        case alertConfirmButtonTapped
        case alertDismissed

        // Delegate Actions (부모와 통신)
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case didLogoutSuccessfully
            case didWithdrawSuccessfully
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer Body
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: UI Actions
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
                
            case .termsButtonTapped:
                // TODO: 서비스 이용 약관 화면으로 이동하는 로직
                return .none
                
            case .privacyPolicyButtonTapped:
                // TODO: 개인정보 처리 방침 화면으로 이동하는 로직
                return .none
                
            case .logoutButtonTapped:
                state.alert = .logout
                return .none
                
            case .withdrawalButtonTapped:
                state.alert = .withdrawal
                return .none
                
            // MARK: Alert Actions
            case .alertConfirmButtonTapped:
                switch state.alert {
                case .logout:
                    // TODO: 실제 로그아웃 API 호출
                    return .run { send in
                        // try await self.authClient.logout()
                        await send(.delegate(.didLogoutSuccessfully))
                    }
                case .withdrawal:
                    // TODO: 실제 회원 탈퇴 API 호출
                    return .run { send in
                        // try await self.userClient.withdraw()
                        await send(.delegate(.didWithdrawSuccessfully))
                    }
                case .none:
                    return .none
                }
                
            case .alertDismissed:
                state.alert = nil
                return .none
                
            case .delegate:
                // 부모 Reducer에서 처리할 액션입니다.
                return .none
            }
        }
    }
}
