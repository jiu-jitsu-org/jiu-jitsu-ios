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
        // 설정 스택에 push되는 커뮤니티 웹 서브뷰('차단한 회원' 등, #56)
        var path = StackState<Path.State>()

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

    @Reducer
    public enum Destination {
        case notificationSetting(NotificationSettingFeature)
    }

    @Reducer
    public enum Path {
        case communityDetail(CommunityDetailFeature)
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)
        case path(StackAction<Path.State, Path.Action>)
        // 부모(AppTab)가 토큰 갱신·만료를 서브뷰 웹뷰에도 전파한다.
        case session(CommunityDetailFeature.SessionUpdate)

        public enum ViewAction: Sendable {
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
            // 알림 화면이 닫힐 때 이어받은 저장의 결과.
            case notificationSettingSaveResponse(TaskResult<NoticeSetting>)
            case showToast(ToastState)
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            case didLogoutSuccessfully
            case didWithdrawSuccessfully
            case loginRequested
            // '차단한 회원' 탭 → 부모가 커뮤니티와 같은 origin·최신 토큰으로 서브뷰를 push한다.
            case blockedUsersRequested
            // 웹 서브뷰의 인증류 위임(로그인 유도·로그아웃·토큰 갱신) → 부모가 커뮤니티와 같은 흐름으로 처리한다.
            case webSubview(CommunityDetailFeature.Action.DelegateAction)
        }
    }

    // MARK: - Dependencies
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.noticeClient) var noticeClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer Body
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: UI Actions
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

            // 서브뷰 안의 중첩 OPEN_SUBVIEW는 설정 스택에 push로 쌓는다. (동일 origin 검증은 상세가 위임 전에 끝냈다)
            case let .path(.element(id: id, action: .communityDetail(.delegate(.openSubviewRequested(payload))))):
                guard
                    case let .communityDetail(source)? = state.path[id: id],
                    let url = URL(string: payload.url)
                else { return .none }
                state.path.append(.communityDetail(.init(
                    url: url,
                    title: payload.title,
                    accessToken: source.accessToken
                )))
                return .none

            case let .path(.element(id: _, action: .communityDetail(.delegate(delegate)))):
                return .send(.delegate(.webSubview(delegate)))

            case let .session(update):
                for id in state.path.ids {
                    if case var .communityDetail(detail)? = state.path[id: id] {
                        CommunityDetailFeature.apply(update, into: &detail)
                        state.path[id: id] = .communityDetail(detail)
                    }
                }
                return .none

            case .path:
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
                // 서버 로그아웃 결과와 상관없이 항상 로그아웃한다(정책 2026-10-21, #65).
                // 서버 세션은 만료되며 정리되고, 웹 요청 로그아웃(`AppTabFeature.performWebLogout`)과 동작을 맞춘다.
                return .run { send in
                    do {
                        let isSuccess = try await authClient.serverLogout()
                        if !isSuccess {
                            Log.trace("Server logout returned false — proceeding with local logout", category: .network, level: .error)
                        }
                    } catch {
                        Log.trace("Server logout failed — proceeding with local logout: \(error)", category: .network, level: .error)
                    }
                    await authClient.signOut()
                    await send(.delegate(.didLogoutSuccessfully))
                }

            case .view(.confirmWithdrawal):
                return .run { send in
                    await send(.internal(.withdrawalResponse(
                        await TaskResult { try await
                            userClient.withdrawal()
                        }
                    )))
                }

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
                // 아직 서버에 반영되지 않은 값이 있으면 화면보다 오래 사는 여기서 대신 저장한다.
                // (dismiss는 자식 상태가 지워지기 전에 이 리듀서를 거치므로 마지막 값을 읽을 수 있다)
                guard case let .notificationSetting(notification)? = state.destination,
                      let setting = notification.unsavedSetting
                else { return .none }
                return .run { send in
                    await send(.internal(.notificationSettingSaveResponse(
                        await TaskResult { try await noticeClient.updateSetting(setting) }
                    )))
                }

            case .internal(.notificationSettingSaveResponse(.success)):
                return .none

            case let .internal(.notificationSettingSaveResponse(.failure(error))):
                Log.trace("알림 화면 이탈 후 설정 저장 실패: \(error)", category: .network, level: .error)
                return handleError(error)

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
        .forEach(\.path, action: \.path)
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

extension SettingsFeature.Destination.State: Equatable, Sendable {}
extension SettingsFeature.Destination.Action: Sendable {}
extension SettingsFeature.Path.State: Equatable, Sendable {}
extension SettingsFeature.Path.Action: Sendable {}
