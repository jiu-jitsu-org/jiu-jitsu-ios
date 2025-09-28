//
//  Font+.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI
import CoreText // 폰트 등록을 위해 CoreText를 import 합니다.

private final class FontInitializer {
    static let shared = FontInitializer()
    
    private init() {
        let fontNames = [
            "Pretendard-Black.otf",
            "Pretendard-Bold.otf",
            "Pretendard-ExtraBold.otf",
            "Pretendard-SemiBold.otf",
            "Pretendard-Medium.otf",
            "Pretendard-Regular.otf",
            "Pretendard-Light.otf",
            "Pretendard-ExtraLight.otf",
            "Pretendard-Thin.otf"
        ]
        
        for fontName in fontNames {
            FontInitializer.registerFont(fontName: fontName)
        }
    }
    
    private static func registerFont(fontName: String) {
        // ✅ 현재 코드가 실행되는 번들(DesignSystem.framework)을 찾습니다.
        // FontInitializer.self를 사용하여 번들을 정확히 찾습니다.
        guard let url = Bundle(for: FontInitializer.self).url(forResource: fontName, withExtension: nil) else {
            print("🛑 [DesignSystem] Font not found: \(fontName)")
            return
        }
        
        var error: Unmanaged<CFError>?
        // ✅ 폰트 URL을 통해 시스템 폰트 관리자에 등록합니다.
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            print("🛑 [DesignSystem] Font registration error: \(error.debugDescription)")
        }
    }
}

public extension Font {
    /// 이 static 프로퍼티를 통해 FontInitializer.shared가 최초 한 번 호출되면서
    /// init() 내부의 폰트 등록 코드가 자동으로 실행됩니다.
    private static let fontInitializer = FontInitializer.shared

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
