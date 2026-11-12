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
        // 조회가 실패해도 그대로 둔다 — 서버 값을 모르는 채 토글하면 모든 값을 기본값으로 덮어쓴다.
        var isLoaded: Bool = false

        var isAccountSecurityNotificationEnabled: Bool = true
        var isServiceNoticeNotificationEnabled: Bool = true
        var isCommunityNotificationEnabled: Bool = true
        // 정통망법상 마케팅 알림은 옵트인 → 기본 false
        var isMarketingNotificationEnabled: Bool = false
        // 관심 대회 마감 전날 알림(#255, #281). 서버 기본값과 같이 꺼짐.
        var isCompetitionAlertEnabled: Bool = false

        // 서버에 반영된 것으로 확인된 마지막 값. 저장 실패 시 토글을 이 값으로 되돌린다.
        var lastSavedSetting: NoticeSetting?
        // 저장 요청이 디바운스 대기·응답 대기 중인지. 그동안 다시 조회한 값이 화면 값을 덮지 않게 한다.
        var isSaving = false

        var toast: ToastState?

        public init() {}

        /// 화면에는 바뀌었지만 아직 서버 반영이 확인되지 않은 값(디바운스 대기·응답 대기 중).
        /// 화면이 닫히면 이 화면의 저장 요청도 취소되므로, 부모가 닫힐 때 이 값을 대신 저장한다.
        var unsavedSetting: NoticeSettingUpdate? {
            guard isLoaded, currentSetting != lastSavedSetting else { return nil }
            return settingUpdate
        }

        /// 지금 화면 값의 저장 요청. 관심 대회 알림은 웹도 바꾸므로 이 화면에서 바꿨을 때만 보낸다(#281).
        fileprivate var settingUpdate: NoticeSettingUpdate {
            NoticeSettingUpdate(
                currentSetting,
                includesCompetition: isCompetitionAlertEnabled != lastSavedSetting?.competitionEnabled
            )
        }

        fileprivate var currentSetting: NoticeSetting {
            NoticeSetting(
                securityEnabled: isAccountSecurityNotificationEnabled,
                serviceEnabled: isServiceNoticeNotificationEnabled,
                communityEnabled: isCommunityNotificationEnabled,
                marketingEnabled: isMarketingNotificationEnabled,
                competitionEnabled: isCompetitionAlertEnabled
            )
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        // 부모가 보내는 서버 값 다시 읽기 요청(#281)
        case settingRefreshRequested

        public enum ViewAction: Sendable {
            case onAppear
            case backButtonTapped
            case accountSecurityNotificationToggled(Bool)
            case serviceNoticeNotificationToggled(Bool)
            case communityNotificationToggled(Bool)
            case marketingNotificationToggled(Bool)
            case competitionAlertToggled(Bool)
            case toastButtonTapped(ToastState.Action)
        }

        public enum InternalAction: Sendable {
            case fetchSettingResponse(TaskResult<NoticeSetting>)
            // 보낸 요청과 그 결과. 관심 대회 알림을 보냈는지 보고 켬 안내·서버 값 맞추기를 정한다.
            case updateSettingResponse(NoticeSettingUpdate, TaskResult<NoticeSetting>)
            case triggerUpdateSetting
            case showToast(ToastState)
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            // '관심 대회 알림'을 켬(#257) → 부모(AppTab)가 웹의 '알림 받기'와 같이 기기 알림 상태를 보고 안내한다.
            case competitionAlertTurnedOn
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
                // 서버에서 카테고리별 수신 여부를 읽는다. 처음 열 때와, 위에 쌓인 화면을 닫고 돌아와 다시 나타날 때 불린다.
                // 이 화면이 열린 채 다른 탭(웹의 '알림 받기')에서 켠 값은 부모가 브리지를 받아 settingRefreshRequested로 다시 읽힌다(#281).
                return fetchSetting()

            case .settingRefreshRequested:
                // 웹이 관심 대회 알림을 서버에 저장했다는 브리지(#281) → 부모가 열려 있는 이 화면에 알린다.
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

            case let .view(.competitionAlertToggled(isOn)):
                // 다른 토글과 같이 서버에 저장한다(디바운스·실패 시 되돌리기). 꺼도 대회별 알림 설정은 건드리지 않는다.
                // 기기 알림 안내는 저장이 성공한 뒤에 띄운다(updateSettingResponse).
                guard state.isLoaded else { return .none }
                state.isCompetitionAlertEnabled = isOn
                return .send(.internal(.triggerUpdateSetting))

            // MARK: - Internal Actions

            case .internal(.triggerUpdateSetting):
                // 연속 토글 시 마지막 상태만 반영 (300ms debounce)
                let update = state.settingUpdate
                state.isSaving = true
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(300))
                    await send(.internal(.updateSettingResponse(
                        update,
                        await TaskResult { try await noticeClient.updateSetting(update) }
                    )))
                }
                .cancellable(id: CancelID.updateSetting, cancelInFlight: true)

            case let .internal(.fetchSettingResponse(.success(setting))):
                // 저장 대기·진행 중인 변경은 다시 조회한 값으로 덮지 않는다. 웹이 바꿨을 수 있는 관심 대회 알림만,
                // 이 화면에서 건드리지 않았을 때 서버 값으로 맞춘다(#281).
                if state.isLoaded, let lastSaved = state.lastSavedSetting,
                   state.isSaving || state.currentSetting != lastSaved {
                    guard state.isCompetitionAlertEnabled == lastSaved.competitionEnabled else { return .none }
                    state.isCompetitionAlertEnabled = setting.competitionEnabled
                    state.lastSavedSetting = NoticeSetting(
                        securityEnabled: lastSaved.securityEnabled,
                        serviceEnabled: lastSaved.serviceEnabled,
                        communityEnabled: lastSaved.communityEnabled,
                        marketingEnabled: lastSaved.marketingEnabled,
                        competitionEnabled: setting.competitionEnabled
                    )
                    return .none
                }
                state.apply(setting)
                state.lastSavedSetting = setting
                state.isLoaded = true
                return .none

            case let .internal(.fetchSettingResponse(.failure(error))):
                Log.trace("알림 설정 조회 실패: \(error)", category: .network, level: .error)
                // 이미 불러온 뒤 다시 조회(재진입·브리지)가 실패하면 보이는 값이 그대로 쓸 만하니 로그만 남긴다.
                guard !state.isLoaded else { return .none }
                // 토글은 스켈레톤으로 둔 채 그 자리에서 다시 불러올 수 있게 한다.
                return .send(.internal(.showToast(.init(
                    message: "알림 설정을 불러오지 못했어요.",
                    status: .error,
                    button: .init(title: "다시 시도", action: .done)
                ))))

            case let .internal(.updateSettingResponse(update, .success(setting))):
                state.isSaving = false
                // 관심 대회 알림을 보내지 않았으면 응답 값은 웹이 바꾼 서버 값일 수 있다 — 이 화면에서 건드리지 않았다면 그 값으로 맞춘다.
                if update.competitionEnabled == nil,
                   state.isCompetitionAlertEnabled == state.lastSavedSetting?.competitionEnabled {
                    state.isCompetitionAlertEnabled = setting.competitionEnabled
                }
                state.lastSavedSetting = setting
                // 관심 대회 알림을 켜서 저장했으면(보낸 값은 바뀐 때만 있으니 꺼짐 → 켜짐), 기기 알림이 꺼져 있을 때
                // 알림이 오지 않으니 웹의 '알림 받기'와 같은 안내를 부모가 띄운다.
                guard update.competitionEnabled == true, setting.competitionEnabled else { return .none }
                return .send(.delegate(.competitionAlertTurnedOn))

            case let .internal(.updateSettingResponse(_, .failure(error))):
                state.isSaving = false
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

            case .delegate:
                return .none

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

private extension NotificationSettingFeature.State {
    mutating func apply(_ setting: NoticeSetting) {
        isAccountSecurityNotificationEnabled = setting.securityEnabled
        isServiceNoticeNotificationEnabled = setting.serviceEnabled
        isCommunityNotificationEnabled = setting.communityEnabled
        isMarketingNotificationEnabled = setting.marketingEnabled
        isCompetitionAlertEnabled = setting.competitionEnabled
    }
}
