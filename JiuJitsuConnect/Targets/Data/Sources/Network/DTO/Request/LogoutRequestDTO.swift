//
//  LogoutRequestDTO.swift
//  Data
//
//  Created by suni on 12/1/25.
//

import Foundation

struct LogoutRequestDTO: Encodable, Sendable {
    let accessToken: String
    let refreshToken: String
    /// 서버가 이 기기의 푸시 토큰 연결을 지우는 데 쓴다(BE #197). 없으면 키를 보내지 않는다.
    let fcmToken: String?
}
