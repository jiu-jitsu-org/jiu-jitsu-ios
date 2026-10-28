//
//  CompetitionDivision.swift
//  Domain
//

import Foundation

// 출전 부문(#122) — 대회는 띠 × 체급으로 나가고, 도복·노기를 따로 여는 대회가 많아 메달의 무게가 부문마다 다르다.
// 서버 계약(backend #164)이 아직 없어 rawValue는 요청/응답에 그대로 싣는 가정 값이다.

/// 출전 복장 — 도복(기) / 노기
public enum CompetitionUniform: String, Codable, Equatable, Sendable, CaseIterable, Identifiable, Hashable {
    case gi = "GI"
    case noGi = "NO_GI"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gi: return "도복"
        case .noGi: return "노기"
        }
    }
}

/// 출전 체급 — 체급 상한 또는 앱솔루트(무차별급).
///
/// IBJJF 성인 남자 도복 체급을 기준으로 한다. 성별·복장·대회마다 체급표가 달라
/// 서버 계약이 정해지면 자유 값(문자열)이나 대회별 체급표로 바뀔 수 있다.
public enum CompetitionWeightClass: String, Codable, Equatable, Sendable, CaseIterable, Identifiable, Hashable {
    case under57_5 = "-57.5kg"
    case under64 = "-64kg"
    case under70 = "-70kg"
    case under76 = "-76kg"
    case under82_3 = "-82.3kg"
    case under88_3 = "-88.3kg"
    case under94_3 = "-94.3kg"
    case under100_5 = "-100.5kg"
    case over100_5 = "+100.5kg"
    case absolute = "ABSOLUTE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .absolute: return "앱솔루트"
        default: return rawValue
        }
    }
}
