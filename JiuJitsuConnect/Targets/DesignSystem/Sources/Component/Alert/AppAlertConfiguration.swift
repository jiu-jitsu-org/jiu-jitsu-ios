//
//  AppAlertConfiguration.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - Configuration Models
public struct AppAlertConfiguration {
    let title: Title
    let message: String
    let primaryButton: Button
    let secondaryButton: Button?

    public struct Button {
        let title: String
        let action: () -> Void
        let style: ButtonStyleType
        
        public init(title: String, style: ButtonStyleType = .primary, action: @escaping () -> Void) {
            self.title = title
            self.style = style
            self.action = action
        }
    }
    
    /// 알럿 제목. 대부분은 완성 문자열 하나지만, 가변 길이 텍스트(닉네임 등)에 고정 접미사가 붙는
    /// 제목은 접미사가 잘리지 않도록 말줄임 경계를 알아야 해서 두 조각으로 받는다.
    public enum Title: Equatable {
        case plain(String)
        /// `truncatable`만 tail 말줄임, `suffix`는 항상 온전히 노출(1줄 고정).
        case truncatable(String, suffix: String)
    }

    public init(title: Title, message: String, primaryButton: Button, secondaryButton: Button?) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }

    public init(title: String, message: String, primaryButton: Button, secondaryButton: Button?) {
        self.init(title: .plain(title), message: message, primaryButton: primaryButton, secondaryButton: secondaryButton)
    }
}
