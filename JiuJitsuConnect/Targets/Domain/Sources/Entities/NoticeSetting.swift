//
//  NoticeSetting.swift
//  Domain
//

import Foundation

public struct NoticeSetting: Equatable, Sendable {
    public let securityEnabled: Bool
    public let serviceEnabled: Bool
    public let communityEnabled: Bool
    public let marketingEnabled: Bool
    /// 관심 대회 마감 전날 알림(#281). 서버는 이 값이 켜진 사람에게만 대회 마감 알림을 보낸다.
    public let competitionEnabled: Bool

    public init(
        securityEnabled: Bool,
        serviceEnabled: Bool,
        communityEnabled: Bool,
        marketingEnabled: Bool,
        competitionEnabled: Bool
    ) {
        self.securityEnabled = securityEnabled
        self.serviceEnabled = serviceEnabled
        self.communityEnabled = communityEnabled
        self.marketingEnabled = marketingEnabled
        self.competitionEnabled = competitionEnabled
    }
}

/// 알림 수신 설정 저장 요청(POST `/api/notice/setting`).
/// 관심 대회 알림은 웹(첫 관심 등록 시트)도 바꾸므로, 이 화면에서 바꾼 때만 보내고 아니면 nil로 서버 값을 유지한다(#281).
public struct NoticeSettingUpdate: Equatable, Sendable {
    public let securityEnabled: Bool
    public let serviceEnabled: Bool
    public let communityEnabled: Bool
    public let marketingEnabled: Bool
    public let competitionEnabled: Bool?

    /// - Parameter includesCompetition: false면 관심 대회 알림은 보내지 않는다(서버 값 유지).
    public init(_ setting: NoticeSetting, includesCompetition: Bool) {
        self.securityEnabled = setting.securityEnabled
        self.serviceEnabled = setting.serviceEnabled
        self.communityEnabled = setting.communityEnabled
        self.marketingEnabled = setting.marketingEnabled
        self.competitionEnabled = includesCompetition ? setting.competitionEnabled : nil
    }
}
