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
    /// 프로필 이미지 — 서버 등록 파일 id + URL을 담은 객체. 미설정 시 `nil`.
    let profileImage: ImageRefDTO?
    let snsProvider: String?
    let ownerRequested: Bool?
    /// 관장/사범 인증 제출 이미지 — 파일 id + URL 객체. 미제출 시 `nil`.
    let ownerRequestImage: ImageRefDTO?
    let role: String?
    let status: String?

    func toDomain() -> UserProfile {
        UserProfile(
            // userId는 식별자라 누락 시 의미가 없다 — 방어적으로 0 처리(상위에서 status로 판단 가능)
            userId: userId ?? 0,
            email: email,
            nickname: nickname,
            // BE sentinel("default"/"") → nil 정규화
            profileImageUrl: ProfileImageSentinel.normalize(profileImage?.imageUrl),
            // URL이 유효할 때만 삭제용 파일 id를 노출 (미설정 객체의 id 0 등은 무시)
            profileImageFileId: Self.validFileId(profileImage),
            snsProvider: snsProvider,
            ownerRequested: ownerRequested ?? false,
            // 미제출 placeholder("defaultImage" 등)도 도메인에는 노출하지 않도록 nil 정규화
            ownerRequestImageUrl: Self.normalizeOwnerImage(ownerRequestImage?.imageUrl),
            role: role,
            status: status
        )
    }

    /// 이미지 URL이 실제 값일 때만 파일 id를 반환. 미설정 객체(빈/sentinel URL, id 0)는 `nil`.
    private static func validFileId(_ ref: ImageRefDTO?) -> Int64? {
        guard let ref,
              ProfileImageSentinel.normalize(ref.imageUrl) != nil,
              let id = ref.id, id > 0 else { return nil }
        return id
    }

    /// 인증 이미지 sentinel 정규화. 빈 문자열/기본 placeholder는 "미제출"을 뜻하므로 `nil`.
    private static func normalizeOwnerImage(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty, raw != "default", raw != "defaultImage" else { return nil }
        return raw
    }
}

/// 서버 이미지 참조(`{ id, imageUrl }`) 공통 디코딩 모델.
/// 프로필/인증 이미지 등 "등록된 이미지"를 객체로 내려주는 응답에 재사용한다.
struct ImageRefDTO: Decodable {
    let id: Int64?
    let imageUrl: String?
}
