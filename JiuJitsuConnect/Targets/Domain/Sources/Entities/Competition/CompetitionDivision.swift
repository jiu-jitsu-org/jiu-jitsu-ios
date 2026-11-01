//
//  CompetitionDivision.swift
//  Domain
//

import Foundation

// 출전 부문(#122) — 대회는 띠 × 체급으로 나가고, 도복·노기를 따로 여는 대회가 많아 메달의 무게가 부문마다 다르다.
// rawValue는 서버 요청/응답의 값 그대로다.

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

/// 출전 체급 — "76kg 이하" 같은 체급, 또는 가장 무거운 무제한 체급.
///
/// 체급표는 단체·대회·성별·복장마다 달라 표에서 고르지 않고 숫자로 받는다(예: 76kg 이하).
/// 숫자로 남겨야 어느 단체 체급이든 그대로 기록되고, 나중에 체급별 통계·필터를 만들 수 있다.
/// 대회 체급은 가장 무거운 체급만 빼고 모두 '이하'라, 그 하나는 경계 무게 대신 '무제한'으로 받는다(#190).
/// 앱솔루트(무차별급)는 체급 제한이 없는 부문이라 `Competition.competitionAbsolute`로 따로 두고, 앱솔루트면 체급은 비운다.
public enum CompetitionWeightLimit: Codable, Equatable, Sendable, Hashable {
    /// 이하 — 표기 "-76kg"
    case under(kg: Double)
    /// 무제한 — 가장 무거운 체급. 경계 무게는 대회마다 달라 받지 않는다.
    case unlimited

    /// 서버가 주고받는 이하/초과 값. 무제한은 '초과'로 보낸다.
    public enum Bound: String, Codable, Equatable, Sendable, CaseIterable, Hashable {
        case under = "UNDER"
        case over = "OVER"
    }

    public var bound: Bound {
        switch self {
        case .under: return .under
        case .unlimited: return .over
        }
    }

    /// 경계 무게 — 무제한은 nil
    public var kg: Double? {
        switch self {
        case let .under(kg): return kg
        case .unlimited: return nil
        }
    }
}
