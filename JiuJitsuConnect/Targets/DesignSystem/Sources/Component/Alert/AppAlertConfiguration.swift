//
//  AppAlertConfiguration.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - Configuration Models
public struct AppAlertConfiguration {
    let title: String
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
    
    public init(title: String, message: String, primaryButton: Button, secondaryButton: Button?) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}
