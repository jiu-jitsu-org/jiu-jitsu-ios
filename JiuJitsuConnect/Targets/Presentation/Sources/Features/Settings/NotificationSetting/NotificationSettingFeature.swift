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
        // 첫 GET 성공 전에는 토글을 스켈레톤으로 표시 (잘못된 초기값 노출 방지).
        // 조회가 실패해도 그대로 둔다 — 서버 값을 모르는 채 토글하면 4개 값을 모두 기본값으로 덮어쓴다.
        var isLoaded: Bool = false

        var isAccountSecurityNotificationEnabled: Bool = true
        var isServiceNoticeNotificationEnabled: Bool = true
        var isCommunityNotificationEnabled: Bool = true
        // 정통망법상 마케팅 알림은 옵트인 → 기본 false
        var isMarketingNotificationEnabled: Bool = false

        // 서버에 반영된 것으로 확인된 마지막 값. 저장 실패 시 토글을 이 값으로 되돌린다.
        var lastSavedSetting: NoticeSetting?

        var toast: ToastState?

        public init() {}

        /// 화면에는 바뀌었지만 아직 서버 반영이 확인되지 않은 값(디바운스 대기·응답 대기 중).
        /// 화면이 닫히면 이 화면의 저장 요청도 취소되므로, 부모가 닫힐 때 이 값을 대신 저장한다.
        var unsavedSetting: NoticeSetting? {
            guard isLoaded else { return nil }
            let current = currentSetting
            return current == lastSavedSetting ? nil : current
        }

        fileprivate var currentSetting: NoticeSetting {
            NoticeSetting(
                securityEnabled: isAccountSecurityNotificationEnabled,
                serviceEnabled: isServiceNoticeNotificationEnabled,
                communityEnabled: isCommunityNotificationEnabled,
                marketingEnabled: isMarketingNotificationEnabled
            )
        }
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
                return fetchSetting()

            case .view(.backButtonTapped):
                return .run { _ in await self.dismiss() }

            case let .view(.accountSecurityNotificationToggled(isOn)):
                // 조회 전·실패 시에는 스켈레톤이라 들어올 일이 없지만, 서버 값을 모르는 채 저장하지 않도록 막는다.
                guard state.isLoaded else { return .none }
                state.isAccountSecurityNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.serviceNoticeNotificationToggled(isOn)):
                guard state.isLoaded else { return .none }
                state.isServiceNoticeNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.communityNotificationToggled(isOn)):
                guard state.isLoaded else { return .none }
                state.isCommunityNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            case let .view(.marketingNotificationToggled(isOn)):
                guard state.isLoaded else { return .none }
                state.isMarketingNotificationEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            // MARK: - Internal Actions

            case .internal(.triggerUpdateSetting):
                // 연속 토글 시 마지막 상태만 반영 (300ms debounce)
                let setting = state.currentSetting
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(300))
                    await send(.internal(.updateSettingResponse(
                        await TaskResult { try await noticeClient.updateSetting(setting) }
                    )))
                }
                .cancellable(id: CancelID.updateSetting, cancelInFlight: true)

            case let .internal(.fetchSettingResponse(.success(setting))):
                state.apply(setting)
                state.lastSavedSetting = setting
                state.isLoaded = true
                return .none

            case let .internal(.fetchSettingResponse(.failure(error))):
                Log.trace("알림 설정 조회 실패: \(error)", category: .network, level: .error)
                // 토글은 스켈레톤으로 둔 채 그 자리에서 다시 불러올 수 있게 한다.
                return .send(.internal(.showToast(.init(
                    message: "알림 설정을 불러오지 못했어요.",
                    style: .action(title: "다시 시도", action: .done)
                ))))

            case let .internal(.updateSettingResponse(.success(setting))):
                state.lastSavedSetting = setting
                return .none

            case let .internal(.updateSettingResponse(.failure(error))):
                Log.trace("알림 설정 저장 실패: \(error)", category: .network, level: .error)
                // 화면 값과 서버 값이 어긋나지 않도록 마지막으로 저장된 값으로 되돌린다(#61).
                if let lastSaved = state.lastSavedSetting {
                    state.apply(lastSaved)
                }
                return handleError(error)

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
                // 버튼이 있는 토스트는 조회 실패 안내뿐이라, 아직 못 불러온 상태면 다시 조회한다.
                guard !state.isLoaded else { return .send(.internal(.toastDismissed)) }
                return .merge(.send(.internal(.toastDismissed)), fetchSetting())
            }
        }
    }

    private func fetchSetting() -> Effect<Action> {
        .run { send in
            await send(.internal(.fetchSettingResponse(
                await TaskResult { try await noticeClient.fetchSetting() }
            )))
        }
        .cancellable(id: CancelID.fetchSetting, cancelInFlight: true)
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

private extension NotificationSettingFeature.State {
    mutating func apply(_ setting: NoticeSetting) {
        isAccountSecurityNotificationEnabled = setting.securityEnabled
        isServiceNoticeNotificationEnabled = setting.serviceEnabled
        isCommunityNotificationEnabled = setting.communityEnabled
        isMarketingNotificationEnabled = setting.marketingEnabled
    }
}
