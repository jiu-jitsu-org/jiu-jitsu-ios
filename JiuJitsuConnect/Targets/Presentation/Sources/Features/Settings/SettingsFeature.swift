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
        static let serviceTerms = makeURL(path: "/policies/terms-of-service")
        static let privacyPolicy = makeURL(path: "/policies/privacy-policy")
        static let marketingConsent = makeURL(path: "/policies/marketing-consent")

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

        @Presents var destination: Destination.State?
        @Presents var termsWebCover: TermsWebViewFeature.State?

        public enum Alert: Equatable, Sendable {
            case logout
            case withdrawal
        }

        var alert: Alert? = nil
        public var toast: ToastState?
        // 탈퇴 요청이 서버에 가 있는 동안. MY 스택의 한 화면이라 닫히면 요청도 취소되므로(#241) 그동안 나가지 못하게 막는다.
        var isWithdrawing = false

        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                self.appVersion = version
            } else {
                self.appVersion = "N/A"
            }
        }
    }

    @Reducer
    public enum Destination {
        case notificationSetting(NotificationSettingFeature)
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)

        public enum ViewAction: Sendable {
            // MY에서 밀어 연 설정의 왼쪽 위 뒤로가기(#241)
            case backTapped
            case notificationButtonTapped
            case blockedUsersButtonTapped
            case termsButtonTapped
            case privacyPolicyButtonTapped
            case marketingConsentButtonTapped
            case loginButtonTapped
            case logoutButtonTapped
            case withdrawalButtonTapped
            case confirmLogout
            case confirmWithdrawal
            case alertDismissed
            case toastButtonTapped(ToastState.Action)
        }

        public enum InternalAction: Sendable {
            case withdrawalResponse(TaskResult<Bool>)
            case showToast(ToastState)
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            // 로그아웃 확인 → 부모(AppTab)가 서버 로그아웃·로컬 정리를 한다. 이 화면은 MY 스택의 한 화면이라
            // 스와이프로 닫히면 여기서 돌던 요청이 취소되므로, 화면보다 오래 사는 부모가 맡는다(#241).
            case logoutConfirmed
            case didWithdrawSuccessfully
            // 알림 화면을 나갈 때 서버에 아직 안 간 값 → 부모(MY)가 대신 저장한다. 설정까지 바로 닫아도 저장이 끊기지 않게 한다.
            case notificationSettingSaveRequested(NoticeSetting)
            case loginRequested
            // '차단한 회원' 탭 → 부모가 커뮤니티와 같은 origin·최신 토큰으로 서브뷰를 MY 스택(설정 위)에 push한다.
            case blockedUsersRequested
        }
    }

    // MARK: - Dependencies
    @Dependency(\.userClient) var userClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer Body
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: UI Actions
            case .view(.backTapped):
                guard !state.isWithdrawing else { return .none }
                return .run { _ in await self.dismiss() }

            case .view(.notificationButtonTapped):
                guard !state.authInfo.isGuest else { return .none }
                state.destination = .notificationSetting(NotificationSettingFeature.State())
                return .none

            case .view(.termsButtonTapped):
                guard let url = TermsURL.serviceTerms else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .view(.privacyPolicyButtonTapped):
                guard let url = TermsURL.privacyPolicy else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .view(.marketingConsentButtonTapped):
                // 가입 때 동의한 마케팅 수신 약관을 가입 후에도 다시 볼 수 있게 한다(#74).
                guard let url = TermsURL.marketingConsent else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .termsWebCover(.presented(.delegate(.didClose))):
                state.termsWebCover = nil
                return .none

            case .termsWebCover:
                return .none

            // MARK: - 웹 서브뷰 (차단한 회원)

            case .view(.blockedUsersButtonTapped):
                guard !state.authInfo.isGuest else { return .none }
                return .send(.delegate(.blockedUsersRequested))

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
                // 서버 로그아웃 결과와 상관없이 항상 로그아웃한다(정책 2026-10-21, #65).
                // 웹 요청 로그아웃과 같은 경로(`AppTabFeature.performWebLogout`)로 처리한다.
                return .send(.delegate(.logoutConfirmed))

            case .view(.confirmWithdrawal):
                guard !state.isWithdrawing else { return .none }
                state.isWithdrawing = true
                return .run { send in
                    await send(.internal(.withdrawalResponse(
                        await TaskResult { try await
                            userClient.withdrawal()
                        }
                    )))
                }

            case let .internal(.withdrawalResponse(.success(isSuccess))):
                Log.trace("\(isSuccess)")
                state.isWithdrawing = false

                if isSuccess {
                    return .send(.delegate(.didWithdrawSuccessfully))
                } else {
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, status: .error))))
                }

            case let .internal(.withdrawalResponse(.failure(error))):
                Log.trace("\(error)")
                state.isWithdrawing = false
                return handleError(error)

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
                .cancellable(id: CancelID.toast, cancelInFlight: true)

            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)

            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))

            case .destination(.dismiss):
                // 알림 화면이 닫히면 그 화면의 디바운스·저장 요청도 함께 취소된다(뒤로가기·스와이프 모두).
                // 아직 서버에 반영되지 않은 값이 있으면 설정보다 오래 사는 부모(MY)에게 저장을 넘긴다 — 설정도 MY 스택의
                // 한 화면이라 곧바로 닫히면 여기서 돌던 저장이 함께 취소된다(#241).
                // (dismiss는 자식 상태가 지워지기 전에 이 리듀서를 거치므로 마지막 값을 읽을 수 있다)
                guard case let .notificationSetting(notification)? = state.destination,
                      let setting = notification.unsavedSetting
                else { return .none }
                return .send(.delegate(.notificationSettingSaveRequested(setting)))

            case .destination:
                return .none

            case .delegate, .view, .internal:
                // 부모 Reducer에서 처리할 액션입니다.
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$termsWebCover, action: \.termsWebCover) {
            TermsWebViewFeature()
        }
    }

    private func handleError(_ error: Error) -> Effect<Action> {
        guard let domainError = error as? DomainError else {
            return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, status: .error))))
        }
        let displayError = DomainErrorMapper.toDisplayError(from: domainError)
        switch displayError {
        case .toast(let message), .info(let message), .alert(let message):
            return .send(.internal(.showToast(.init(message: message, status: .error))))
        case .none:
            return .none
        }
    }
}

extension SettingsFeature.Destination.State: Equatable, Sendable {}
extension SettingsFeature.Destination.Action: Sendable {}
