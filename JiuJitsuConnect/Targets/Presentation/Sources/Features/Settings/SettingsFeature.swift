//
//  SettingsFeature.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import ComposableArchitecture
import Foundation
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct SettingsFeature {
    public init() {}
    
    private enum CancelID { case toast }
    
    @ObservableState
    public struct State: Equatable {
        var authInfo: AuthInfo
        var appVersion: String
        
        public enum Alert: Equatable {
            case logout
            case withdrawal
        }
        
        var alert: Alert? = nil
        public var toast: ToastState?
        
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
        
        case _logoutResponse(TaskResult<Bool>)
        case _withdrawalResponse(TaskResult<Bool>)
        
        // Alert Actions
        case confirmLogout
        case confirmWithdrawal
        case alertDismissed
        
        // Toast Actions
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
        
        // Delegate Actions (부모와 통신)
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case didLogoutSuccessfully
            case didWithdrawSuccessfully
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.continuousClock) var clock
    
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
            case .confirmLogout:
                guard let accessToken = state.authInfo.accessToken,
                      let refreshToken = state.authInfo.refreshToken else { return .none }
//                    state.isLoading = true
                return .run { send in
                    await send(._logoutResponse(
                        await TaskResult { try await authClient.serverLogout() }
                    ))
                }
                
            case .confirmWithdrawal:
                // TODO: 실제 회원 탈퇴 API 호출
                return .run { send in
                    await send(._withdrawalResponse(
                        await TaskResult { try await
                            userClient.withdrawal()
                        }
                    ))
                }
                
            case let ._logoutResponse(.success(isSuccess)):
//                state.isLoading = false
                Log.trace("\(isSuccess)")
                
                if isSuccess {
                    return .send(.delegate(.didLogoutSuccessfully))
                } else {
                    return .send(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info)))
                }
                
            case let ._logoutResponse(.failure(error)):
                Log.trace("\(error)")
                //                state.isLoading = false
                
                guard let domainError = error as? DomainError else {
                    return .send(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info)))
                }
                
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.showToast(.init(message: message, style: .info)))
                }
                return .none
                
            case let ._withdrawalResponse(.success(isSuccess)):
//                state.isLoading = false
                Log.trace("\(isSuccess)")
                
                if isSuccess {
                    return .send(.delegate(.didWithdrawSuccessfully))
                } else {
                    return .send(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info)))
                }
                
            case let ._withdrawalResponse(.failure(error)):
                Log.trace("\(error)")
                //                state.isLoading = false
                
                guard let domainError = error as? DomainError else {
                    return .send(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info)))
                }
                
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.showToast(.init(message: message, style: .info)))
                }
                return .none
                
            case .alertDismissed:
                state.alert = nil
                return .none
                
            // MARK: - Toast Actions
            case let .showToast(toastState):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.toastDismissed)
                }
                .cancellable(id: CancelID.toast)
                
            case .toastDismissed:
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .toastButtonTapped:
                return .send(.toastDismissed)
                
            case .delegate:
                // 부모 Reducer에서 처리할 액션입니다.
                return .none
            }
        }
    }
}
