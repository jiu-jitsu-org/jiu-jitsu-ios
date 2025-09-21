//
//  UIApplication+Extension.swift
//  CoreKit
//
//  Created by suni on 9/21/25.
//

import UIKit

public extension UIApplication {
    
    /// 현재 활성화된 Scene의 Root ViewController를 비동기적으로 찾아서 반환합니다.
    static func findRootViewController() async -> UIViewController? {
        await MainActor.run {
            // 현재 연결되고 활성화된 Scene들을 필터링합니다.
            let windowScene = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first as? UIWindowScene
            
            // 해당 Scene에서 현재 Key Window의 Root ViewController를 찾아 반환합니다.
            return windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }
    }
}
