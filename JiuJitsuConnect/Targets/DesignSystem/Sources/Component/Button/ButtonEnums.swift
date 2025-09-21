//
//  ButtonEnums.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import Foundation

public enum ButtonStyleType {
    case primary    // 가장 중요한 액션 버튼 (CTA/Filled)
    case tint       // Primary보다 덜 강조된 액션 버튼
    case text       // 배경이 없는 텍스트 버튼
    case neutral    // 일반적인 액션 버튼
}

public enum ButtonSize {
    case large
    case medium
    case small
    case iconOnly
}
