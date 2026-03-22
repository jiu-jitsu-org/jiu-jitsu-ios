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
    
    /// 벨트 등급에 따른 헤더 배경색
    var headerBackgroundColor: Color {
        switch self {
        case .white:
            return Color.component.myProfileHeader.bg.white
        case .blue:
            return Color.component.myProfileHeader.bg.blue
        case .purple:
            return Color.component.myProfileHeader.bg.purple
        case .brown:
            return Color.component.myProfileHeader.bg.brwon
        case .black:
            return Color.component.myProfileHeader.bg.black
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
