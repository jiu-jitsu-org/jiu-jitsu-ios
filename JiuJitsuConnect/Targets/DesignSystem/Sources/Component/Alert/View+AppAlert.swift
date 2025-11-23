//
//  View+AppAlertStyle.swift
//  DesignSystem
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - View Modifier for Presentation
struct AppAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let alert: AppAlertView
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                alert
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

public extension View {
    func appAlert(isPresented: Binding<Bool>, configuration: AppAlertConfiguration) -> some View {
        self.modifier(
            AppAlertModifier(isPresented: isPresented, alert: AppAlertView(configuration: configuration, isPresented: isPresented))
        )
    }
}
