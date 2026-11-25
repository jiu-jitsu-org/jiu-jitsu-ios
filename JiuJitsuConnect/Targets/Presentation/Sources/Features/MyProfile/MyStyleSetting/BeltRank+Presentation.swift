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

    /// 띠 색 그대로(#320) — MY 헤더 바탕·사진 링·벨트 카드가 같은 색을 쓴다.
    var beltColor: Color {
        let belt = Color.component.myBelt
        switch self {
        case .white: return belt.white
        case .blue: return belt.blue
        case .purple: return belt.purple
        case .brown: return belt.brown
        case .black: return belt.black
        }
    }

    /// 바탕이 밝은 띠 — 그 위 글자·아이콘·무늬를 어둡게 칠한다(키즈 노랑띠도 여기에 들어간다).
    var isLightBelt: Bool { self == .white }

    /// 링·카드에 칠하는 띠 색. 흰띠만 헤더 바탕(#F7F8F8) 위에서 뜨게 순백.
    var beltSurfaceColor: Color {
        self == .white ? Color.component.myBelt.whiteRing : beltColor
    }
}

extension Optional where Wrapped == BeltRank {
    /// MY · 남의 프로필(#337) 헤더 바탕(#320). 띠가 없으면 기본색.
    var myHeaderColor: Color {
        self?.beltColor ?? Color.component.myProfileHeader.bg.default
    }

    /// MY 헤더 위 글자·아이콘 색 — 밝은 띠면 어둡게, 아니면 흰색
    var myHeaderForeground: Color {
        self?.isLightBelt == true
            ? Color.component.myBelt.onLight
            : Color.component.list.setting.background
    }
}
