//
//  NoticeSettingResponseDTO.swift
//  Data
//

import Foundation
import Domain

struct NoticeSettingResponseDTO: Decodable, Sendable {
    let securityEnabled: Bool
    let serviceEnabled: Bool
    let communityEnabled: Bool
    let marketingEnabled: Bool
    // 관심 대회 마감 알림(#281, backend#193). 서버 기본값은 false.
    // 이 키가 없는 구 서버에서도 알림 설정 화면 전체가 막히지 않게 없으면 꺼짐으로 읽는다.
    let competitionEnabled: Bool?

    func toDomain() -> NoticeSetting {
        NoticeSetting(
            securityEnabled: securityEnabled,
            serviceEnabled: serviceEnabled,
            communityEnabled: communityEnabled,
            marketingEnabled: marketingEnabled,
            competitionEnabled: competitionEnabled ?? false
        )
    }
}
