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
