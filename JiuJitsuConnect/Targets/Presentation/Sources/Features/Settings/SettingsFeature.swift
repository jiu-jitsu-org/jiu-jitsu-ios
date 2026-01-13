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
public struct SettingsFeature: Sendable {
    public init() {}
    
    private enum CancelID { case toast }
    
    @ObservableState
    public struct State: Equatable {
        var authInfo: AuthInfo
        var appVersion: String
        
        public enum Alert: Equatable, Sendable {
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
    public enum Action: Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Equatable, Sendable {
            case backButtonTapped
            case termsButtonTapped
            case privacyPolicyButtonTapped
            case logoutButtonTapped
            case withdrawalButtonTapped
            case confirmLogout
            case confirmWithdrawal
            case alertDismissed
            case toastButtonTapped(ToastState.Action)
        }
        
        public enum InternalAction: Equatable, Sendable {
            case logoutResponse(TaskResult<Bool>)
            case withdrawalResponse(TaskResult<Bool>)
            case showToast(ToastState)
            case toastDismissed
        }
        
        public enum DelegateAction: Equatable, Sendable {
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
            case .view(.backButtonTapped):
                return .run { _ in await self.dismiss() }
                
            case .view(.termsButtonTapped):
                // TODO: 서비스 이용 약관 화면으로 이동하는 로직
                return .none
                
            case .view(.privacyPolicyButtonTapped):
                // TODO: 개인정보 처리 방침 화면으로 이동하는 로직
                return .none
                
            case .view(.logoutButtonTapped):
                state.alert = .logout
                return .none
                
            case .view(.withdrawalButtonTapped):
                state.alert = .withdrawal
                return .none
                
            // MARK: Alert Actions
            case .view(.confirmLogout):
//                    state.isLoading = true
                return .run { send in
                    await send(.internal(.logoutResponse(
                        await TaskResult { try await authClient.serverLogout() }
                    )))
                }
                
            case .view(.confirmWithdrawal):
                // TODO: 실제 회원 탈퇴 API 호출
                return .run { send in
                    await send(.internal(.withdrawalResponse(
                        await TaskResult { try await
                            userClient.withdrawal()
                        }
                    )))
                }
                
            case let .internal(.logoutResponse(.success(isSuccess))):
//                state.isLoading = false
                Log.trace("\(isSuccess)")
                
                if isSuccess {
                    return .send(.delegate(.didLogoutSuccessfully))
                } else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }
                
            case let .internal(.logoutResponse(.failure(error))):
                Log.trace("\(error)")
                //                state.isLoading = false
                
                guard let domainError = error as? DomainError else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }
                
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.internal(.showToast(.init(message: message, style: .info))))
                }
                return .none
                
            case let .internal(.withdrawalResponse(.success(isSuccess))):
//                state.isLoading = false
                Log.trace("\(isSuccess)")
                
                if isSuccess {
                    return .send(.delegate(.didWithdrawSuccessfully))
                } else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }
                
            case let .internal(.withdrawalResponse(.failure(error))):
                Log.trace("\(error)")
                //                state.isLoading = false
                
                guard let domainError = error as? DomainError else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }
                
                let displayError = DomainErrorMapper.toDisplayError(from: domainError)
                if case .toast(let message) = displayError {
                    return .send(.internal(.showToast(.init(message: message, style: .info))))
                }
                return .none
                
            case .view(.alertDismissed):
                state.alert = nil
                return .none
                
            // MARK: - Toast Actions
            case let .internal(.showToast(toastState)):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.internal(.toastDismissed))
                }
                .cancellable(id: CancelID.toast)
                
            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))
                
            case .delegate, .view, .internal:
                // 부모 Reducer에서 처리할 액션입니다.
                return .none
            }
        }
    }
}
