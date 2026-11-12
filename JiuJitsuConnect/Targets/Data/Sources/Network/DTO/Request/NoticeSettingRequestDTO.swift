//
//  NoticeSettingRequestDTO.swift
//  Data
//

import Foundation

struct NoticeSettingRequestDTO: Encodable, Sendable {
    let securityEnabled: Bool
    let serviceEnabled: Bool
    let communityEnabled: Bool
    let marketingEnabled: Bool
    // 관심 대회 마감 알림(#281). nil이면 키를 빼고 보내 서버가 기존 값을 유지한다.
    let competitionEnabled: Bool?
}
