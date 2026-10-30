//
//  CompetitionDivision.swift
//  Domain
//

import Foundation

// 출전 부문(#122) — 대회는 띠 × 체급으로 나가고, 도복·노기를 따로 여는 대회가 많아 메달의 무게가 부문마다 다르다.
// 서버 계약(backend #164)이 개발 서버에 없어 아직 서버로 보내거나 받지 않는다 — 앱 안에서만 쓰는 값이다.

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

/// 출전 체급 — 체급 경계 무게와 그 이하/초과.
///
/// 체급표는 단체·대회·성별·복장마다 달라 표에서 고르지 않고 숫자로 받는다(예: 76kg 이하).
/// 숫자로 남겨야 어느 단체 체급이든 그대로 기록되고, 나중에 체급별 통계·필터를 만들 수 있다.
/// 앱솔루트(무차별급)는 체급 제한이 없는 부문이라 `Competition.competitionAbsolute`로 따로 두고, 앱솔루트면 체급은 비운다.
public struct CompetitionWeightLimit: Codable, Equatable, Sendable, Hashable {
    public enum Bound: String, Codable, Equatable, Sendable, CaseIterable, Hashable {
        /// 이하 — 표기 "-76kg"
        case under = "UNDER"
        /// 초과 — 표기 "+100.5kg"
        case over = "OVER"
    }

    public let kg: Double
    public let bound: Bound

    public init(kg: Double, bound: Bound) {
        self.kg = kg
        self.bound = bound
    }
}
