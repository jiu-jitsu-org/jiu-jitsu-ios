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

    private enum TermsURL {
        static let serviceTerms = makeURL(path: "/service-info")
        static let privacyPolicy = makeURL(path: "/service-info")

        private static func makeURL(path: String) -> URL? {
            guard
                let baseString = Bundle.main.object(forInfoDictionaryKey: "WEB_URL") as? String,
                !baseString.isEmpty,
                let base = URL(string: baseString)
            else {
                Log.trace("WEB_URL is not set in Info.plist", category: .system, level: .error)
                return nil
            }
            return base.appendingPathComponent(path)
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        var authInfo: AuthInfo
        var appVersion: String

        // 알림 수신 여부 (카테고리별). 마케팅은 정통망법상 옵트인 → 기본 false.
        // TODO: 서버 동기화 전까지 임시 로컬 상태. API 연동 후 초기값/저장은 Repository 경유.
        var isAccountSecurityNotificationEnabled: Bool = true
        var isServiceNoticeNotificationEnabled: Bool = true
        var isCommunityNotificationEnabled: Bool = true
        var isMarketingNotificationEnabled: Bool = false

        @Presents var termsWebCover: TermsWebViewFeature.State?

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
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)

        public enum ViewAction: Sendable {
            case termsButtonTapped
            case privacyPolicyButtonTapped
            case loginButtonTapped
            case logoutButtonTapped
            case withdrawalButtonTapped
            case confirmLogout
            case confirmWithdrawal
            case alertDismissed
            case toastButtonTapped(ToastState.Action)
            case accountSecurityNotificationToggled(Bool)
            case serviceNoticeNotificationToggled(Bool)
            case communityNotificationToggled(Bool)
            case marketingNotificationToggled(Bool)
        }

        public enum InternalAction: Sendable {
            case logoutResponse(TaskResult<Bool>)
            case withdrawalResponse(TaskResult<Bool>)
            case showToast(ToastState)
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            case didLogoutSuccessfully
            case didWithdrawSuccessfully
            case loginRequested
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer Body
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: UI Actions
            case .view(.termsButtonTapped):
                guard let url = TermsURL.serviceTerms else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .view(.privacyPolicyButtonTapped):
                guard let url = TermsURL.privacyPolicy else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .termsWebCover(.presented(.delegate(.didClose))):
                state.termsWebCover = nil
                return .none

            case .termsWebCover:
                return .none
                
            case .view(.loginButtonTapped):
                return .send(.delegate(.loginRequested))

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
                    return .run { send in
                        await authClient.signOut()
                        await send(.delegate(.didLogoutSuccessfully))
                    }
                } else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }
                
            case let .internal(.logoutResponse(.failure(error))):
                Log.trace("\(error)")
                return handleError(error)

            case let .internal(.withdrawalResponse(.success(isSuccess))):
                Log.trace("\(isSuccess)")

                if isSuccess {
                    return .send(.delegate(.didWithdrawSuccessfully))
                } else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
                }

            case let .internal(.withdrawalResponse(.failure(error))):
                Log.trace("\(error)")
                return handleError(error)
                
            case let .view(.accountSecurityNotificationToggled(isOn)):
                state.isAccountSecurityNotificationEnabled = isOn
                // TODO: 알림 설정 API 연동 - 계정·보안 알림 수신 여부 서버 반영
                return .none

            case let .view(.serviceNoticeNotificationToggled(isOn)):
                state.isServiceNoticeNotificationEnabled = isOn
                // TODO: 알림 설정 API 연동 - 서비스 공지 알림 수신 여부 서버 반영
                return .none

            case let .view(.communityNotificationToggled(isOn)):
                state.isCommunityNotificationEnabled = isOn
                // TODO: 알림 설정 API 연동 - 커뮤니티 활동 알림 수신 동의 여부 서버 반영
                return .none

            case let .view(.marketingNotificationToggled(isOn)):
                state.isMarketingNotificationEnabled = isOn
                // TODO: 알림 설정 API 연동 - 마케팅 정보 수신 동의 여부 서버 반영
                //       정통망법상 광고성 정보는 별도 동의 필요 — 회원가입/약관 흐름과 연동 검토
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
        .ifLet(\.$termsWebCover, action: \.termsWebCover) {
            TermsWebViewFeature()
        }
    }

    private func handleError(_ error: Error) -> Effect<Action> {
        guard let domainError = error as? DomainError else {
            return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
        }
        let displayError = DomainErrorMapper.toDisplayError(from: domainError)
        switch displayError {
        case .toast(let message), .info(let message), .alert(let message):
            return .send(.internal(.showToast(.init(message: message, style: .info))))
        case .none:
            return .none
        }
    }
}
