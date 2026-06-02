//
//  GetUserProfileResponseDTO.swift
//  Data
//
//  Created by suni on 6/2/26.
//

import Foundation
import Domain

/// `GET /api/user/profile` 응답의 `data` 영역.
///
/// `NetworkService.request<T>`가 `BaseResponseDTO<T>`로 감싸 디코드한 뒤 `.data`만
/// 반환하므로 inner 필드만 표현한다. 스키마 미세 변경에도 깨지지 않도록 모든 필드를
/// 옵셔널로 둔다(`UpdateUserProfileResponseDTO`와 동일한 방침).
struct GetUserProfileResponseDTO: Decodable {
    let userId: Int?
    let email: String?
    let nickname: String?
    let profileImageUrl: String?
    let snsProvider: String?
    let ownerRequested: Bool?
    let ownerRequestImageUrl: String?
    let role: String?
    let status: String?

    func toDomain() -> UserProfile {
        UserProfile(
            // userId는 식별자라 누락 시 의미가 없다 — 방어적으로 0 처리(상위에서 status로 판단 가능)
            userId: userId ?? 0,
            email: email,
            nickname: nickname,
            // BE sentinel("default"/"") → nil 정규화
            profileImageUrl: ProfileImageSentinel.normalize(profileImageUrl),
            snsProvider: snsProvider,
            ownerRequested: ownerRequested ?? false,
            // 미제출 placeholder("defaultImage" 등)도 도메인에는 노출하지 않도록 nil 정규화
            ownerRequestImageUrl: Self.normalizeOwnerImage(ownerRequestImageUrl),
            role: role,
            status: status
        )
    }

    /// 인증 이미지 sentinel 정규화. 빈 문자열/기본 placeholder는 "미제출"을 뜻하므로 `nil`.
    private static func normalizeOwnerImage(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty, raw != "default", raw != "defaultImage" else { return nil }
        return raw
    }
}
