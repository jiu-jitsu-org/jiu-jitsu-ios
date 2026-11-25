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
    /// 관장/사범 인증 신청 상태. 누락 시 미신청으로 본다.
    let ownerVerification: OwnerVerificationDTO?
    let role: String?
    let status: String?
    let analyticsId: String?
    let accountType: String?

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
            ownerVerification: ownerVerification?.toDomain() ?? .notRequested,
            role: role,
            status: status,
            analyticsId: analyticsId,
            accountType: accountType
        )
    }

    /// 이미지 URL이 실제 값일 때만 파일 id를 반환. 미설정 객체(빈/sentinel URL, id 0)는 `nil`.
    private static func validFileId(_ ref: ImageRefDTO?) -> Int64? {
        guard let ref,
              ProfileImageSentinel.normalize(ref.imageUrl) != nil,
              let id = ref.id, id > 0 else { return nil }
        return id
    }
}

/// `ownerVerification` — 관장/사범 인증 신청 상태 (`UserProfileResponse` 공통).
struct OwnerVerificationDTO: Decodable {
    let status: String?
    /// 제출한 인증 서류 — 파일 id + URL 객체. 미제출 시 `nil`.
    let documentImage: ImageRefDTO?
    let rejectReason: String?
    /// 신청 일시. 서버는 시간대 없는 `LocalDateTime`(서울 시각, 예: `2026-11-17T14:03:22.123456`)으로 준다.
    let requestedAt: String?

    private enum CodingKeys: String, CodingKey {
        case status, documentImage, rejectReason, requestedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        documentImage = try container.decodeIfPresent(ImageRefDTO.self, forKey: .documentImage)
        rejectReason = try container.decodeIfPresent(String.self, forKey: .rejectReason)
        // 신청 날짜는 시트 부제에만 쓰는 곁가지라, 형식이 바뀌어도(배열 등) 프로필 전체를 못 읽게 두지 않는다.
        requestedAt = try? container.decodeIfPresent(String.self, forKey: .requestedAt)
    }

    func toDomain() -> OwnerVerification {
        OwnerVerification(
            // 모르는 상태값은 미신청으로 둬서 시트가 신청 화면으로 열리게 한다
            status: status.flatMap(OwnerVerification.Status.init(rawValue:)) ?? .notRequested,
            // 미제출 placeholder("defaultImage" 등)도 도메인에는 노출하지 않도록 nil 정규화
            documentImageUrl: Self.normalizeDocumentImage(documentImage?.imageUrl),
            rejectReason: rejectReason
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 },
            requestedAt: Self.parseRequestedAt(requestedAt)
        )
    }

    /// 서버 신청 일시 → `Date`. 읽지 못하면 `nil`(화면은 날짜 없이 안내한다).
    /// - 시간대가 붙어 오면(`Z`, `+09:00`) 그대로 읽는다.
    /// - 시간대가 없으면 서버 시각(Asia/Seoul)으로 본다. 소수 초 자릿수가 0~9자리로 달라 초까지만 읽는다.
    private static func parseRequestedAt(_ raw: String?) -> Date? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()
        for options: ISO8601DateFormatter.Options in [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime]
        ] {
            iso.formatOptions = options
            if let date = iso.date(from: raw) { return date }
        }

        let local = raw.replacingOccurrences(of: " ", with: "T")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        for (format, length) in [("yyyy-MM-dd'T'HH:mm:ss", 19), ("yyyy-MM-dd'T'HH:mm", 16), ("yyyy-MM-dd", 10)] {
            formatter.dateFormat = format
            if let date = formatter.date(from: String(local.prefix(length))) { return date }
        }
        return nil
    }

    /// 인증 이미지 sentinel 정규화. 빈 문자열/기본 placeholder는 "미제출"을 뜻하므로 `nil`.
    private static func normalizeDocumentImage(_ raw: String?) -> String? {
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
