//
//  AppInfoRequestDTO.swift
//  Data
//
//  API 전송 전용 모델 (Swagger: fcmToken, deviceId, osType, osVersion).
//  Domain ↔ DTO 매핑은 `UserMapper.swift`에 정의함.
//

import Foundation

struct AppInfoRequestDTO: Encodable, Sendable {
    let fcmToken: String
    let deviceId: String
    let osType: String
    let osVersion: String
}
