//
//  LineHeightModifier.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

struct LineHeightModifier: ViewModifier {
    let lineHeight: CGFloat
    
    func body(content: Content) -> some View {
        content
            .lineSpacing(lineHeight - UIFont.systemFont(ofSize: 1).lineHeight)
            .padding(.vertical, (lineHeight - UIFont.systemFont(ofSize: 1).lineHeight) / 2)
    }
}

public extension View {
    /// 텍스트의 행간(Line Height)을 디자인 시스템에 맞게 설정합니다.
    func lineHeight(_ lineHeight: CGFloat) -> some View {
        self.modifier(LineHeightModifier(lineHeight: lineHeight))
    }
}
