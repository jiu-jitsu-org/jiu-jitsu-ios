//
//  NotificationSettingFeature.swift
//  Presentation
//
//  설정 → 알림 (카테고리별 수신 여부 토글) 화면.
//

import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct NotificationSettingFeature: Sendable {
    public init() {}

    // 연속 토글 시 마지막 상태만 서버에 반영하기 위한 debounce
    private enum CancelID { case fetchSetting, updateSetting, toast }

    @ObservableState
    public struct State: Equatable, Sendable {
        // 첫 GET 완료 전에는 토글을 스켈레톤으로 표시 (잘못된 초기값 노출 방지)
        var isLoaded: Bool = false

        var isAccountSecurityNotificationEnabled: Bool = true
        var isServiceNoticeNotificationEnabled: Bool = true
        var isCommunityNotificationEnabled: Bool = true
        // 정통망법상 마케팅 알림은 옵트인 → 기본 false
        var isMarketingNotificationEnabled: Bool = false

        var toast: ToastState?

        public init() {}
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        public enum ViewAction: Sendable {
            case onAppear
            case backButtonTapped
            case accountSecurityNotificationToggled(Bool)
            case serviceNoticeNotificationToggled(Bool)
            case communityNotificationToggled(Bool)
            case marketingNotificationToggled(Bool)
            case toastButtonTapped(ToastState.Action)
        }

        public enum InternalAction: Sendable {
            case fetchSettingResponse(TaskResult<NoticeSetting>)
            case updateSettingResponse(TaskResult<NoticeSetting>)
            case triggerUpdateSetting
            case showToast(ToastState)
            case toastDismissed
        }
    }

    @Dependency(\.noticeClient) var noticeClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: - View Actions

            case .view(.onAppear):
                // 서버에서 카테고리별 수신 여부 초기값 로드
                return .run { send in
                    await send(.internal(.fetchSettingResponse(
                        await TaskResult { try await noticeClient.fetchSetting() }
                    )))
                }
                .cancellable(id: CancelID.fetchSetting, cancelInFlight: true)

            case .view(.backButtonTapped):
                return .run { _ in await self.dismiss() }

            case let .view(.accountSecurityNotificationToggled(isOn)):
                state.isAccountSecurityNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.serviceNoticeNotificationToggled(isOn)):
                state.isServiceNoticeNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.communityNotificationToggled(isOn)):
                state.isCommunityNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.marketingNotificationToggled(isOn)):
                state.isMarketingNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            // MARK: - Internal Actions

            case .internal(.triggerUpdateSetting):
                // 연속 토글 시 마지막 상태만 반영 (300ms debounce)
                let setting = NoticeSetting(
                    securityEnabled: state.isAccountSecurityNotificationEnabled,
                    serviceEnabled: state.isServiceNoticeNotificationEnabled,
                    communityEnabled: state.isCommunityNotificationEnabled,
                    marketingEnabled: state.isMarketingNotificationEnabled
                )
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(300))
                    await send(.internal(.updateSettingResponse(
                        await TaskResult { try await noticeClient.updateSetting(setting) }
                    )))
                }
                .cancellable(id: CancelID.updateSetting, cancelInFlight: true)

            case let .internal(.fetchSettingResponse(.success(setting))):
                state.isAccountSecurityNotificationEnabled = setting.securityEnabled
                state.isServiceNoticeNotificationEnabled = setting.serviceEnabled
                state.isCommunityNotificationEnabled = setting.communityEnabled
                state.isMarketingNotificationEnabled = setting.marketingEnabled
                state.isLoaded = true
                return .none

            case let .internal(.fetchSettingResponse(.failure(error))):
                Log.trace("알림 설정 조회 실패: \(error)", category: .network, level: .error)
                // 조회 실패 시에도 화면은 사용 가능하도록 공개 (기본값 노출 + 토스트 안내)
                state.isLoaded = true
                return handleError(error)

            case .internal(.updateSettingResponse(.success)):
                return .none

            case let .internal(.updateSettingResponse(.failure(error))):
                Log.trace("알림 설정 저장 실패: \(error)", category: .network, level: .error)
                return handleError(error)

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
            }
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
