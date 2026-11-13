//
//  BeltRank+Presentation.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import Domain
import DesignSystem

// MARK: - BeltRank Presentation Extensions

extension BeltRank {
    /// 벨트 등급에 따른 아이콘 이미지
    var beltIcon: Image {
        switch self {
        case .white:
            return Assets.MyProfile.Icon.beltWhite.swiftUIImage
        case .blue:
            return Assets.MyProfile.Icon.beltBlue.swiftUIImage
        case .purple:
            return Assets.MyProfile.Icon.beltPurple.swiftUIImage
        case .brown:
            return Assets.MyProfile.Icon.beltBrown.swiftUIImage
        case .black:
            return Assets.MyProfile.Icon.beltBlack.swiftUIImage
        }
    }
    
    /// 공용 띠 고르기 버튼에 그릴 띠 색
    var selectButtonColor: BeltSelectButton.BeltColor {
        switch self {
        case .white: return .white
        case .blue: return .blue
        case .purple: return .purple
        case .brown: return .brown
        case .black: return .black
        }
    }

    /// 벨트 등급에 따른 헤더 배경색
    /// 띠 몸 색으로 칠하되, 몸 색이 너무 밝거나(흰띠) 어두우면(검은띠) 그 띠의 바 색으로 칠한다 —
    /// 흰띠는 검은 바(먹색), 검은띠는 빨간 바.
    var headerBackgroundColor: Color {
        switch self {
        case .white:
            return Color.component.myProfileHeader.bg.black
        case .blue:
            return Color.component.myProfileHeader.bg.blue
        case .purple:
            return Color.component.myProfileHeader.bg.purple
        case .brown:
            return Color.component.myProfileHeader.bg.brwon
        case .black:
            return Color.component.myProfileHeader.bg.blackBeltBar
        }
    }
}

extension Optional where Wrapped == BeltRank {
    /// Optional BeltRank의 헤더 배경색 (nil일 경우 기본색)
    var headerBackgroundColor: Color {
        switch self {
        case .none:
            return Color.component.myProfileHeader.bg.default
        case .some(let beltRank):
            return beltRank.headerBackgroundColor
        }
    }
}
