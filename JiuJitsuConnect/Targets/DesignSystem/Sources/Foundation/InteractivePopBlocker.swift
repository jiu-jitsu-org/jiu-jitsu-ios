import SwiftUI
import CoreKit

/// 이 화면이 맨 위에 있는 동안 내비게이션 스와이프 백을 막는다. (`UINavigationController+SwipeBack` 참고)
/// 막을 화면의 `.background { InteractivePopBlocker() }`로 넣는다.
/// 막힌 스와이프 대신 할 일(웹에 뒤로가기 넘기기 등, #115)이 있으면 `onBlocked`로 건다.
public struct InteractivePopBlocker: UIViewControllerRepresentable {
    /// 막힌 스와이프 백 시도마다 불린다.
    private let onBlocked: (() -> Void)?

    public init(onBlocked: (() -> Void)? = nil) {
        self.onBlocked = onBlocked
    }

    public func makeUIViewController(context: Context) -> InteractivePopBlockingViewController {
        let controller = InteractivePopBlockingViewController()
        controller.onInteractivePopBlocked = onBlocked
        return controller
    }

    public func updateUIViewController(_ uiViewController: InteractivePopBlockingViewController, context: Context) {
        uiViewController.onInteractivePopBlocked = onBlocked
    }
}
