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
    }
}
