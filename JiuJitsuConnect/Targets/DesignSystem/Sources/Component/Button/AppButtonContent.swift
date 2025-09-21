//
//  AppButtonContent.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public struct AppButtonContent: View {
    private let title: String?
    private let leftIcon: Image?
    private let rightIcon: Image?
    private let size: ButtonSize
    
    public init(
        title: String?,
        leftIcon: Image? = nil,
        rightIcon: Image? = nil,
        size: ButtonSize
    ) {
        self.title = title
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.size = size
    }
    
    public var body: some View {
        if size == .iconOnly {
            // 아이콘 전용 버튼일 경우
            if let icon = leftIcon ?? rightIcon {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
            }
        } else {
            // 일반 버튼일 경우
            HStack(spacing: iconSpacing) {
                if let leftIcon {
                    leftIcon
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                }
                
                if let title {
                    Text(title)
                }
                
                if let rightIcon {
                    rightIcon
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                }
            }
        }
    }
    
    // 사이즈별 아이콘 크기
    private var iconSize: CGFloat {
        switch size {
        case .large: return 24
        case .medium: return 20
        case .small, .iconOnly: return 16
        }
    }
    
    // 사이즈별 아이콘과 텍스트 간격
    private var iconSpacing: CGFloat {
        switch size {
        case .large: return 4
        case .medium: return 4
        case .small: return 2
        case .iconOnly: return 0
        }
    }
}
