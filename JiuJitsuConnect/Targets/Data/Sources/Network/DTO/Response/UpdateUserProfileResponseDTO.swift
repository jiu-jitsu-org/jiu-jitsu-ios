//
//  UpdateUserProfileResponseDTO.swift
//  Data
//
//  Created by suni on 5/26/26.
//

import Foundation

/// `PUT /api/user/profile` 응답의 `data` 영역.
///
/// 갱신된 user 객체가 통째로 내려온다. `NetworkService.request<T>`가
/// `BaseResponseDTO<T>`로 감싸 디코드한 뒤 `.data`만 반환하므로 inner 필드만 표현한다.
/// 현재는 호출 측에서 응답 본문을 직접 사용하지 않지만, 디코딩 자체가 성공해야
/// `BaseResponseDTO.success` 검증 경로로 진입한다 — 모든 필드를 옵셔널로 두어
/// 스키마 미세 변경에도 깨지지 않게 한다.
struct UpdateUserProfileResponseDTO: Decodable {
    let userId: Int?
    let nickname: String?
    let profileImageUrl: String?
    let email: String?
    let snsProvider: String?
    let status: String?
    let role: String?
    let ownerRequested: Bool?
}
