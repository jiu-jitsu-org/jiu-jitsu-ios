//
//  DeactivateRequestDTO.swift
//  Data
//
//  Created by suni on 11/8/25.
//

import Foundation

/// 회원 탈퇴(DELETE `/api/user`) 요청 body.
///
/// 서버는 Apple 토큰 revoke에 `authorizationCode`를 사용한다(BE `DeactivateRequest`, #41).
/// 카카오/구글은 이 값이 필요 없어 body 자체를 보내지 않는다(서버는 `@RequestBody(required = false)`).
struct DeactivateRequestDTO: Encodable, Sendable {
    let authorizationCode: String
}
