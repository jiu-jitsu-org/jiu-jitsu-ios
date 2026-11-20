//
//  AppFeature+SettingsAnalytics.swift
//  Presentation
//
//  설정 기록(#430). 알림 설정 그룹 켬 · 끔(notification_setting_change, 저장 응답에서),
//  문의 메일(support_contact, 설정 문의하기 · 관장 사범 인증 변경 문의).
//  웹이 바꾼 관심 대회 알림은 웹이 남긴다.
//

import ComposableArchitecture
import Domain

extension AppFeature.Analytics {
    func reduceSettingsEvent(into state: inout State, action: Action) {
        guard let (myAction, myPage) = Self.myProfileAction(of: action, in: state) else { return }
        switch myAction {
        case let .path(.element(id: id, action: .settings(settingsAction))):
            reduceSettingsScreenEvent(settingsAction, settings: myPage.path[id: id], state: &state)

        // 알림 화면을 나간 뒤 MY가 대신 저장한 값
        case let .internal(.notificationSettingSaved(update)):
            logNotificationChanges(update, since: state.analytics.handedOffNotificationBaseline)
            state.analytics.handedOffNotificationBaseline = nil

        case .sheet(.presented(.instructorVerification(.delegate(.contactOpened)))):
            log(.supportContact(from: .ownerCert, result: .opened))

        case .sheet(.presented(.instructorVerification(.delegate(.mailUnavailable)))):
            log(.supportContact(from: .ownerCert, result: .copied))

        default:
            break
        }
    }

    private func reduceSettingsScreenEvent(
        _ action: SettingsFeature.Action,
        settings: MyProfileFeature.Path.State?,
        state: inout State
    ) {
        switch action {
        case let .internal(.inquiryOpenFinished(opened)):
            log(.supportContact(from: .settings, result: opened ? .opened : .copied))

        // 저장 요청을 시작할 때 서버 값(아직 응답 전이라 화면의 마지막 저장값)을 잡아 둔다.
        // 디바운스로 요청이 다시 시작돼도 그 사이 응답이 없어 같은 값이다.
        case .destination(.presented(.notificationSetting(.internal(.triggerUpdateSetting)))):
            guard
                case let .settings(settingsState)? = settings,
                case let .notificationSetting(notification)? = settingsState.destination
            else { return }
            state.analytics.pendingNotificationBaseline = notification.lastSavedSetting

        case let .destination(.presented(.notificationSetting(.internal(.updateSettingResponse(update, .success))))):
            logNotificationChanges(update, since: state.analytics.pendingNotificationBaseline)
            state.analytics.pendingNotificationBaseline = nil

        case .destination(.presented(.notificationSetting(.internal(.updateSettingResponse(_, .failure))))):
            state.analytics.pendingNotificationBaseline = nil

        // 화면이 닫히며 남은 저장을 MY에 넘김 → 기준값도 MY 저장 몫으로 옮긴다.
        case .delegate(.notificationSettingSaveRequested):
            state.analytics.handedOffNotificationBaseline = state.analytics.pendingNotificationBaseline
            state.analytics.pendingNotificationBaseline = nil

        default:
            break
        }
    }

    /// 저장 전 값과 다른 그룹마다 한 건. 켰다 다시 끄고 저장하면 바뀐 게 없어 남기지 않는다.
    /// 관심 대회 알림은 이 화면에서 바꿔 보낸 때만 본다.
    private func logNotificationChanges(_ update: NoticeSettingUpdate, since baseline: NoticeSetting?) {
        guard let baseline else { return }
        let changes: [(AnalyticsEvent.NotificationSection, Bool, Bool?)] = [
            (.security, baseline.securityEnabled, update.securityEnabled),
            (.service, baseline.serviceEnabled, update.serviceEnabled),
            (.community, baseline.communityEnabled, update.communityEnabled),
            (.competition, baseline.competitionEnabled, update.competitionEnabled),
            (.marketing, baseline.marketingEnabled, update.marketingEnabled)
        ]
        for (section, before, after) in changes {
            guard let after, after != before else { continue }
            log(.notificationSettingChange(section, isOn: after))
        }
    }
}
