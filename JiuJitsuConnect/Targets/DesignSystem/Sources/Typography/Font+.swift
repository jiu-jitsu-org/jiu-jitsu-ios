//
//  Font+.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public extension Font {
    /// Pretendard 폰트 네임스페이스
    static let pretendard = Pretendard()
}

public struct Pretendard {
    // MARK: - Title
    public let title1 = Font.custom("Pretendard-SemiBold", size: 22)
    public let title2 = Font.custom("Pretendard-SemiBold", size: 20)
    public let title3 = Font.custom("Pretendard-SemiBold", size: 18)

    // MARK: - Body
    public let bodyM = Font.custom("Pretendard-Medium", size: 16)
    public let bodyS = Font.custom("Pretendard-Medium", size: 14)

    // MARK: - Label
    public let labelM = Font.custom("Pretendard-Medium", size: 12)
    public let labelS = Font.custom("Pretendard-Medium", size: 10)
    
    // MARK: - Button
    public let buttonL = Font.custom("Pretendard-SemiBold", size: 18)
    public let buttonM = Font.custom("Pretendard-SemiBold", size: 16)
    public let buttonS = Font.custom("Pretendard-SemiBold", size: 12)
    
    /// 사이즈와 웨이트를 직접 지정해야 할 경우 사용
    public func custom(weight: Pretendard.Weight, size: CGFloat) -> Font {
        return Font.custom("Pretendard-\(weight.rawValue)", size: size)
    }
    
    public enum Weight: String {
        case black = "Black"
        case bold = "Bold"
        case extraBold = "ExtraBold"
        case semiBold = "SemiBold"
        case medium = "Medium"
        case regular = "Regular"
        case light = "Light"
        case extraLight = "ExtraLight"
        case thin = "Thin"
    }
}
