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
    /// 대회 날짜를 YYYY.MM 형식으로 포맷팅
    var formattedDate: String {
        String(format: "%d.%02d", competitionYear, competitionMonth)
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
