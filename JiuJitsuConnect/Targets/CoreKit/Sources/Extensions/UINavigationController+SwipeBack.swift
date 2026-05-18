//
//  UINavigationController+SwipeBack.swift
//  CoreKit
//

import UIKit

// SwiftUI의 `.navigationBarHidden(true)` 적용 시 시스템 백버튼이 사라지면서
// `interactivePopGestureRecognizer`까지 함께 비활성화되어 스와이프백이 동작하지 않는
// 기본 동작을 우회한다. 스택 깊이가 2 이상일 때만 제스처를 허용하므로
// 루트 화면(Splash / 탭 루트)에서는 자동으로 동작하지 않는다.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1
    }
}
