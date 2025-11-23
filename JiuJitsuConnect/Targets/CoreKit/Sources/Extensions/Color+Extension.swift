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
    /// - `Color(hex: "#FF5733")` (RGB)
    /// - `Color(hex: "#40FF5733")` (ARGB)
    /// - `Color(hex: "A733FF")` (# 제외)
    ///
    /// - Parameters:
    ///   - hex: 6자리 또는 8자리의 16진수 색상 문자열. '#' 접두사는 선택 사항입니다.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            red = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x000000FF) / 255.0
            alpha = CGFloat((rgb & 0xFF000000) >> 24) / 255.0

        } else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
