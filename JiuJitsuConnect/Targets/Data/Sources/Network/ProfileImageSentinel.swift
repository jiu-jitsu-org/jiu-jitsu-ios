//
//  ProfileImageSentinel.swift
//  Data
//
//  Created by suni on 5/31/26.
//

import Foundation

/// 프로필 이미지 URL의 BE 합의 sentinel.
///
/// BE는 "이미지 없음" 상태를 빈 문자열(`""`)로 받는다.
/// 도메인 모델(`CommunityProfile.profileImageUrl: String?` 등)은 sentinel을 알 필요가
/// 없도록 Data 레이어에서 `nil`로 정규화한다 — 요청 인코딩 시 다시 sentinel로 매핑.
///
/// 응답 정규화는 historical sentinel(`"default"`)도 함께 흡수해 호환성을 유지한다.
enum ProfileImageSentinel {
    /// "이미지 없음/삭제"를 의미하는 요청 sentinel.
    static let empty = ""

    /// 응답으로 받은 raw 값을 도메인 표현(`String?`)으로 정규화한다.
    /// 빈 문자열, 또는 historical sentinel `"default"`이면 `nil`을 반환.
    static func normalize(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty, raw != "default" else { return nil }
        return raw
    }
}
