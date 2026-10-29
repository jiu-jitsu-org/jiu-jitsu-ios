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

    /// 출전 부문 표기 — "도복 -76kg", "노기", "앱솔루트". 복장·체급을 모두 비웠으면 nil.
    var divisionText: String? {
        let parts = [competitionUniform?.displayName, competitionWeightClass?.displayName].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// 프로필 대회 줄의 상세 줄 — "2026 · 브라운 · 도복 -76kg". 입력하지 않은 부문 항목은 뺀다.
    var detailText: String {
        [formattedYear, competitionBelt?.displayName, divisionText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// 부문 + 메달 — "도복 -76kg 은메달". 부문이 없으면 메달만.
    var divisionResultText: String {
        [divisionText, competitionRank.displayName]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    /// 완료 화면 한 줄 — "2026 서울 오픈 · 도복 -76kg 은메달".
    /// 등록된 대회명에는 연도가 들어 있는 경우가 많아, 이름에 연도가 없을 때만 앞에 붙인다.
    var completionSummary: String {
        let year = formattedYear
        let title = competitionName.contains(year) ? competitionName : "\(year) \(competitionName)"
        guard let divisionText else { return "\(title) \(competitionRank.displayName)" }
        return "\(title) · \(divisionText) \(competitionRank.displayName)"
    }
}

// MARK: - CompetitionRank Presentation Extensions

extension CompetitionRank {
    /// 부문 줄에 붙이는 짧은 이름 — "도복 -76kg 은"
    var shortName: String {
        switch self {
        case .gold: return "금"
        case .silver: return "은"
        case .bronze: return "동"
        case .participation: return "참가"
        }
    }

    /// 묶인 대회 줄의 대표 메달을 고를 때 쓰는 순서 — 작을수록 높은 메달.
    var medalOrder: Int {
        switch self {
        case .gold: return 0
        case .silver: return 1
        case .bronze: return 2
        case .participation: return 3
        }
    }

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
