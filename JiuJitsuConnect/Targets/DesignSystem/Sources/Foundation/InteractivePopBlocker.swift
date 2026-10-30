import SwiftUI
import CoreKit

/// 이 화면이 맨 위에 있는 동안 내비게이션 스와이프 백을 막는다. (`UINavigationController+SwipeBack` 참고)
/// 막을 화면의 `.background { InteractivePopBlocker() }`로 넣는다.
public struct InteractivePopBlocker: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> InteractivePopBlockingViewController {
        InteractivePopBlockingViewController()
    }

    public func updateUIViewController(_ uiViewController: InteractivePopBlockingViewController, context: Context) {}
}
