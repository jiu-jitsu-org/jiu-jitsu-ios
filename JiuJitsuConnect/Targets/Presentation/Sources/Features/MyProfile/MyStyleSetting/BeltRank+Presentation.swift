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
    /// 흰띠는 검은 바(먹색), 검은띠는 빨간 바. 웹 대회 탭 위 그라데이션도 같은 규칙이다.
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
            return Self.blackBeltBarRed
        }
    }

    /// 검은띠의 빨간 바 색 — 앱 띠 그림(웹 public/images/characters/belts/black.webp)의 빨간 바에서 뽑았다(웹 토큰 red-belt-bar).
    /// 경고에 쓰는 Red-500(#FF1D0D)은 넓은 머리 바탕에 깔면 눈이 아파, 실제 띠처럼 깊고 차분한 빨강을 쓴다.
    private static let blackBeltBarRed = Color(hex: "AC2828")
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
