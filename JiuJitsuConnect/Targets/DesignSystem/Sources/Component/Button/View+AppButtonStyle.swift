//
//  Button+Extension.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public extension View {
    /// 버튼에 JiuJitsuConnect 디자인 시스템 스타일을 적용합니다.
    /// - Parameters:
    ///   - style: 버튼의 종류 (primary, tint, text, neutral)
    ///   - size: 버튼의 크기 (large, medium, small, iconOnly)
    ///   - hasRightIcon: 오른쪽 아이콘 유무에 따라 패딩을 조절할지 여부
    ///   - width: 버튼의 고정 너비 (nil이면 부모 크기에 맞춤)
    ///   - height: 버튼의 고정 높이 (nil이면 부모 크기에 맞춤)
    ///   - horizontalPadding: 좌우 패딩 직접 지정 (nil이면 size 기본값 사용). 텍스트가 동적으로 변할 때 width 대신 사용 권장.
    func appButtonStyle(
        _ style: ButtonStyleType,
        size: ButtonSize,
        hasRightIcon: Bool = false,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        horizontalPadding: CGFloat? = nil
    ) -> some View {
        self.buttonStyle(AppButtonStyle(style: style, size: size, hasRightIcon: hasRightIcon, width: width, height: height, horizontalPadding: horizontalPadding))
    }
}

// MARK: - Usage Examples
/*
 
 import SwiftUI
 import DesignSystem

 struct ButtonUsageExample: View {
     var body: some View {
         VStack(spacing: 15) {
             // MARK: - Primary Style
             Button(action: {}) {
                 AppButtonContent(title: "Primary Large", size: .large)
             }
             .appButtonStyle(.primary, size: .large)

             // MARK: - Tint Style (with Right Icon)
             Button(action: {}) {
                 AppButtonContent(
                     title: "Tint Medium",
                     rightIcon: Image(systemName: "arrow.right"),
                     size: .medium
                 )
             }
             .appButtonStyle(.tint, size: .medium, hasRightIcon: true)

             // MARK: - Neutral Style (Disabled)
             Button(action: {}) {
                 AppButtonContent(title: "Neutral Small", size: .small)
             }
             .appButtonStyle(.neutral, size: .small)
             .disabled(true)

             // MARK: - Text Style (with Left Icon)
             Button(action: {}) {
                 AppButtonContent(
                     title: "Text Button",
                     leftIcon: Image(systemName: "plus"),
                     size: .medium
                 )
             }
             .appButtonStyle(.text, size: .medium)

             // MARK: - Icon-Only Style
             Button(action: {}) {
                 AppButtonContent(
                     title: nil,
                     leftIcon: Image(systemName: "heart.fill"),
                     size: .iconOnly
                 )
             }
             .appButtonStyle(.primary, size: .iconOnly)
         }
         .padding()
     }
 }

*/
