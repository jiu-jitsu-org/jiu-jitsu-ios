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
        guard viewControllers.count > 1 else { return false }
        // 맨 위 화면이 스와이프 백을 막겠다고 표시했으면 허용하지 않는다(글쓰기 등 이탈 확인이 필요한 화면, #82).
        // 막을 때는 그 화면에 알려, 닫는 대신 할 일(웹에 뒤로가기 넘기기 등, #115)을 하게 한다.
        guard let blocker = topViewController?.view.interactivePopBlocker else { return true }
        blocker.onInteractivePopBlocked?()
        return false
    }
}

/// 이 뷰 컨트롤러의 뷰가 화면에 있는 동안 내비게이션 스와이프 백을 막는다는 표시.
/// SwiftUI에서는 `UIViewControllerRepresentable`로 이 타입의 컨트롤러를 화면에 넣어 쓴다.
/// 제스처 on/off를 직접 바꾸지 않고 시작 시점에 표시를 찾으므로, 화면이 닫히면 저절로 풀린다.
open class InteractivePopBlockingViewController: UIViewController {
    /// 스와이프 백이 시작되려다 막혔을 때 불린다(스와이프 한 번에 한 번).
    /// 화면은 그대로 두고 그 자리에서 할 일(웹의 이탈 확인 띄우기 등)을 건다.
    public var onInteractivePopBlocked: (() -> Void)?
}

private extension UIView {
    var interactivePopBlocker: InteractivePopBlockingViewController? {
        if let blocker = next as? InteractivePopBlockingViewController { return blocker }
        for subview in subviews {
            if let blocker = subview.interactivePopBlocker { return blocker }
        }
        return nil
    }
}
