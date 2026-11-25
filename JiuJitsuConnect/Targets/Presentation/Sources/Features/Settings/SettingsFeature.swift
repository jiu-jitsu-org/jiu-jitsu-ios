//
//  SettingsFeature.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import ComposableArchitecture
import Foundation
import UIKit
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
        // 공지사항(#369) — 웹 공지 화면(jiu-jitsu-frontend#509)을 약관과 같은 웹뷰로 연다.
        static let notices = makeURL(path: "/notices")

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
        // 서버 최신 버전과 비교한 결과(#326). 아직 확인 못 했으면 nil — 지금처럼 버전만 보인다.
        var isLatestVersion: Bool?

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
        // 지금 로그인한 수단(#380). 계정 묶음 맨 위 "카카오로 로그인 중"에 쓴다.
        // 같은 사람도 소셜마다 다른 계정이라, 로그아웃 뒤 같은 수단으로 돌아오도록 알려 둔다.
        var loginProvider: SNSProvider?
        // 탈퇴 알럿을 연 계정이 Apple 회원인지(#398). Apple은 탈퇴 직전 확인 창이 한 번 더 떠서 알럿에서 미리 알린다.
        var isAppleWithdrawal = false
        // 문의 메일을 여는 중(#331). 빠르게 두 번 눌러도 메일 화면·토스트가 한 번만 뜨게 한다.
        var isOpeningInquiry = false

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
        // 이용 통계(#476) — 수집 끄기 스위치는 한 단계 아래 화면에 둔다
        case analyticsSetting(AnalyticsSettingFeature)
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)

        public enum ViewAction: Sendable {
            case onAppear
            // MY에서 밀어 연 설정의 왼쪽 위 뒤로가기(#241)
            case backTapped
            // 버전 정보의 '업데이트'(#326)
            case updateButtonTapped
            case notificationButtonTapped
            case analyticsButtonTapped
            case blockedUsersButtonTapped
            case noticesButtonTapped
            case termsButtonTapped
            case privacyPolicyButtonTapped
            case marketingConsentButtonTapped
            case inquiryButtonTapped
            case loginButtonTapped
            case logoutButtonTapped
            case withdrawalButtonTapped
            case confirmLogout
            case confirmWithdrawal
            case alertDismissed
            case toastButtonTapped(ToastState.Action)
        }

        public enum InternalAction: Sendable {
            case versionPolicyLoaded(AppVersionPolicy)
            case withdrawalResponse(TaskResult<Bool>)
            // opened: 메일 앱이 열렸는지(못 열면 주소를 복사했다). 루트의 분석 기록이 본다(#430).
            case inquiryOpenFinished(opened: Bool)
            case showToast(ToastState)
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            // 로그아웃 확인 → 부모(AppTab)가 서버 로그아웃·로컬 정리를 한다. 이 화면은 MY 스택의 한 화면이라
            // 스와이프로 닫히면 여기서 돌던 요청이 취소되므로, 화면보다 오래 사는 부모가 맡는다(#241).
            case logoutConfirmed
            case didWithdrawSuccessfully
            // 알림 화면을 나갈 때 서버에 아직 안 간 값 → 부모(MY)가 대신 저장한다. 설정까지 바로 닫아도 저장이 끊기지 않게 한다.
            case notificationSettingSaveRequested(NoticeSettingUpdate)
            case loginRequested
            // '차단한 회원' 탭 → 부모가 커뮤니티와 같은 origin·최신 토큰으로 서브뷰를 MY 스택(설정 위)에 push한다.
            case blockedUsersRequested
            // 알림 화면에서 '관심 대회 알림'을 켬(#257) → 부모(AppTab)가 기기 알림이 꺼져 있으면 안내한다.
            case competitionAlertTurnedOn
        }
    }

    // MARK: - Dependencies
    @Dependency(\.userClient) var userClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.appVersionClient) var appVersionClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.date) var date
    @Dependency(\.recentErrorClient) var recentErrorClient
    @Dependency(\.analyticsClient) var analyticsClient

    // MARK: - Reducer Body
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: UI Actions
            case .view(.onAppear):
                state.loginProvider = state.authInfo.isGuest ? nil : authClient.storedProvider()
                // 스플래시에서 받은 결과를 쓰고, 확인이 실패했거나 오래됐으면 한 번 더 받는다(#326).
                if let checked = appVersionClient.lastChecked() {
                    state.isLatestVersion = Self.isLatest(state.appVersion, policy: checked.policy)
                }
                guard appVersionClient.needsRecheck(now: date.now) else { return .none }
                return .run { send in
                    guard let policy = try? await appVersionClient.fetchPolicy() else { return }
                    await send(.internal(.versionPolicyLoaded(policy)))
                }

            case let .internal(.versionPolicyLoaded(policy)):
                state.isLatestVersion = Self.isLatest(state.appVersion, policy: policy)
                return .none

            case .view(.updateButtonTapped):
                guard let storeURL = appVersionClient.storeURL() else { return .none }
                return .run { _ in await openURL(storeURL) }

            case .view(.backTapped):
                guard !state.isWithdrawing else { return .none }
                return .run { _ in await self.dismiss() }

            case .view(.notificationButtonTapped):
                guard !state.authInfo.isGuest else { return .none }
                state.destination = .notificationSetting(NotificationSettingFeature.State())
                return .none

            case .view(.analyticsButtonTapped):
                state.destination = .analyticsSetting(AnalyticsSettingFeature.State(
                    isEnabled: analyticsClient.isCollectionEnabled(),
                    privacyPolicyURL: TermsURL.privacyPolicy
                ))
                return .none

            case .view(.noticesButtonTapped):
                guard let url = TermsURL.notices else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
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

            case .view(.inquiryButtonTapped):
                guard !state.isOpeningInquiry, let email = SupportContact.email else { return .none }
                let userId = state.authInfo.isGuest ? nil : state.authInfo.userInfo?.userId
                let info = SupportInquiryMail.DeviceInfo.current(userId: userId, recentError: recentErrorClient.latest())
                guard let url = SupportInquiryMail.url(to: email, info: info) else {
                    Log.trace("문의 메일 주소를 만들지 못함: \(email)", category: .view, level: .error)
                    return .none
                }
                state.isOpeningInquiry = true
                return .run { send in
                    let opened = await openURL(url)
                    if !opened {
                        // 관장 사범 인증 문의와 같게, 메일 앱이 없으면 주소를 복사해 두고 알린다.
                        Log.trace("문의 메일을 열지 못함(메일 앱 없음 등)", category: .view, level: .error)
                        await MainActor.run { UIPasteboard.general.string = email }
                        await send(.internal(.showToast(.init(
                            message: "메일 앱을 열 수 없어 문의 주소를 복사했어요", status: .info
                        ))))
                    }
                    await send(.internal(.inquiryOpenFinished(opened: opened)))
                }

            case .internal(.inquiryOpenFinished):
                state.isOpeningInquiry = false
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
                state.isAppleWithdrawal = authClient.storedProvider() == .apple
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
                        await TaskResult {
                            // Apple 회원은 탈퇴 시점 재인증으로 새 authorizationCode를 받아 서버 revoke에 쓴다.
                            // 비-Apple이면 nil → 기존처럼 body 없이 탈퇴. 재인증을 취소하면 여기서 throw되어 탈퇴가 중단된다(#41).
                            let authorizationCode = try await authClient.appleAuthorizationCodeForWithdrawal()
                            return try await userClient.withdrawal(authorizationCode)
                        }
                    )))
                }

            case let .internal(.withdrawalResponse(.success(isSuccess))):
                Log.trace("\(isSuccess)")
                state.isWithdrawing = false

                if isSuccess {
                    return .send(.delegate(.didWithdrawSuccessfully))
                } else {
                    // 서버가 탈퇴를 처리하지 못했다고 답함(오류 코드 없음).
                    analyticsClient.logEvent(.errorShown(.server))
                    return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, status: .error))))
                }

            case let .internal(.withdrawalResponse(.failure(error))):
                Log.trace("\(error)")
                state.isWithdrawing = false
                // Apple 확인 창을 닫으면 탈퇴가 멈춘다. 로그인 취소처럼 말없이 넘기면 탈퇴됐는지 알 수 없다(#398).
                if case .signInCancelled? = error as? DomainError {
                    return .send(.internal(.showToast(.init(message: "Apple 확인을 취소해 탈퇴하지 않았어요.", status: .info))))
                }
                // 실패를 알리고, 오류 코드는 문의 메일에 남긴다(#379).
                guard let domainError = error as? DomainError,
                      let notice = DomainErrorMapper.authFailure(from: domainError)
                else { return handleError(error) }
                if let code = notice.code {
                    recentErrorClient.record(RecentError(code: code, occurredAt: date.now))
                }
                analyticsClient.logErrorShown(error)
                return .send(.internal(.showToast(.init(message: notice.message, status: .error))))

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

            case .destination(.presented(.notificationSetting(.delegate(.competitionAlertTurnedOn)))):
                return .send(.delegate(.competitionAlertTurnedOn))

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
        analyticsClient.logErrorShown(error)
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

extension SettingsFeature {
    /// 버전 정보 줄의 표시(#326). 최소 버전보다 낮아도 '업데이트'로 같이 보인다.
    static func isLatest(_ currentVersion: String, policy: AppVersionPolicy) -> Bool {
        policy.requirement(for: currentVersion) == .upToDate
    }
}
