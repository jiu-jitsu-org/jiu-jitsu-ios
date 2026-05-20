//
//  NotificationSettingFeature.swift
//  Presentation
//
//  설정 → 알림 (카테고리별 수신 여부 토글) 2-step 화면.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct NotificationSettingFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        // 알림 수신 여부 (카테고리별). 마케팅은 정통망법상 옵트인 → 기본 false.
        // TODO: 서버 동기화 전까지 임시 로컬 상태. API 연동 후 초기값/저장은 Repository 경유.
        var isAccountSecurityNotificationEnabled: Bool
        var isServiceNoticeNotificationEnabled: Bool
        var isCommunityNotificationEnabled: Bool
        var isMarketingNotificationEnabled: Bool

        public init(
            isAccountSecurityNotificationEnabled: Bool = true,
            isServiceNoticeNotificationEnabled: Bool = true,
            isCommunityNotificationEnabled: Bool = true,
            isMarketingNotificationEnabled: Bool = false
        ) {
            self.isAccountSecurityNotificationEnabled = isAccountSecurityNotificationEnabled
            self.isServiceNoticeNotificationEnabled = isServiceNoticeNotificationEnabled
            self.isCommunityNotificationEnabled = isCommunityNotificationEnabled
            self.isMarketingNotificationEnabled = isMarketingNotificationEnabled
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)

        public enum ViewAction: Sendable {
            case backButtonTapped
            case accountSecurityNotificationToggled(Bool)
            case serviceNoticeNotificationToggled(Bool)
            case communityNotificationToggled(Bool)
            case marketingNotificationToggled(Bool)
        }
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.backButtonTapped):
                return .run { _ in await self.dismiss() }

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
            }
        }
    }
}
