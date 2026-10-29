//
//  Competition+Presentation.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import Domain
import DesignSystem

// MARK: - Competition Presentation Extensions

extension Competition {
    /// 대회 연도 표시 — 연도만 받으므로(#120) 월이 남아 있는 기존 기록도 연도만 보여 준다.
    var formattedYear: String {
        String(competitionYear)
    }

    /// 출전 부문 표기 — "도복 -76kg", "노기 앱솔루트", "-76kg 앱솔루트". 복장·체급·앱솔루트를 모두 비웠으면 nil.
    var divisionText: String? {
        let parts = [
            competitionUniform?.displayName,
            competitionWeightLimit?.displayText,
            competitionAbsolute ? "앱솔루트" : nil
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// 프로필 대회 줄의 상세 줄 — "2026 · 브라운 · 도복 -76kg". 입력하지 않은 부문 항목은 뺀다.
    var detailText: String {
        [formattedYear, competitionBelt?.displayName, divisionText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

// MARK: - CompetitionWeightLimit Presentation Extensions

extension CompetitionWeightLimit {
    /// 무게 숫자만 — "76", "82.3". 소수점이 없으면 정수로 보이고 입력란에도 그대로 쓴다.
    var kgText: String {
        kg.formatted(.number.precision(.fractionLength(0...1)).grouping(.never))
    }

    /// 대회에서 쓰는 체급 표기 — 이하는 "-76kg", 초과는 "+100.5kg".
    var displayText: String {
        "\(bound == .under ? "-" : "+")\(kgText)kg"
    }
}

// MARK: - CompetitionRank Presentation Extensions

extension CompetitionRank {
    /// 순위에 따른 메달 아이콘 이미지
    var medalImage: Image {
        switch self {
        case .gold:
            return Assets.MyProfile.Icon.medalGold.swiftUIImage
        case .silver:
            return Assets.MyProfile.Icon.medalSilver.swiftUIImage
        case .bronze:
            return Assets.MyProfile.Icon.medalBronze.swiftUIImage
        case .participation:
            return Assets.MyProfile.Icon.medalDefault.swiftUIImage
        }
    }
}
