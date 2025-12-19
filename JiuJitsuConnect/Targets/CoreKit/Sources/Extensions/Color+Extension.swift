//
//  Color+Extension.swift
//  CoreKit
//
//  Created by suni on 11/23/25.
//

import SwiftUI
import Foundation

public extension Color {
    /// HEX 색상 코드를 사용하여 Color를 초기화합니다.
    /// 예시:
    /// - `Color(hex: "#FF5733")` (6자리 RGB)
    /// - `Color(hex: "#40FF5733")` (8자리 ARGB)
    /// - `Color(hex: "A733FF")` (# 제외)
    /// - `Color(hex: "F00")` (3자리 RGB)
    ///
    /// - Parameters:
    ///   - hex: 3자리, 6자리 또는 8자리의 16진수 색상 문자열. '#' 접두사는 선택 사항입니다.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
