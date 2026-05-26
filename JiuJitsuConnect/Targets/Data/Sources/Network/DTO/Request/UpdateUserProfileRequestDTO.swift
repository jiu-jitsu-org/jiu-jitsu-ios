//
//  UpdateUserProfileRequestDTO.swift
//  Data
//
//  Created by suni on 5/26/26.
//

import Foundation

/// `PUT /api/user/profile` 요청 DTO.
///
/// BE가 `nickname`을 nil로 받지 못해(required) 항상 현재값 또는 새 값을 전달한다.
/// `profileImageUrl`은 `encode(_:forKey:)`를 직접 호출해 `nil`이면 JSON `null`로
/// 명시 전송 — "이미지 삭제" 의도를 "변경 없음(키 생략)"과 명확히 구분한다.
///
/// 참고: BE가 동일 닉네임 재전송에도 중복 체크를 수행하는 이슈가 보고됨 (R0003).
/// 해당 BE 수정 전까진 닉네임 변경 케이스가 아닌데도 닉네임 키가 항상 들어간다.
struct UpdateUserProfileRequestDTO: Encodable {
    let nickname: String
    let profileImageUrl: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
        // Optional<String>을 encode하면 nil은 `null`로 직렬화된다 (encodeIfPresent와 다름)
        try container.encode(profileImageUrl, forKey: .profileImageUrl)
    }

    enum CodingKeys: String, CodingKey {
        case nickname
        case profileImageUrl
    }
}
