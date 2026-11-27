import SwiftUI
import UIKit

/// 이 뷰를 담은 스크롤 하나만 끝에서 튕기지 않게 한다.
/// 띠 색 머리를 화면 맨 위까지 깐 화면(MY · 남의 프로필)에서 위로 당겨도 머리 위 빈 바탕이 드러나지 않게 쓴다.
/// `ScrollView` 내용의 `.background { ScrollBounceDisabler() }`로 넣는다.
///
/// `UIScrollView.appearance().bounces = false`는 그 뒤 만들어지는 앱의 모든 스크롤에 걸려 쓰지 않는다(QA A2-16).
public struct ScrollBounceDisabler: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> FinderView {
        FinderView()
    }

    public func updateUIView(_ uiView: FinderView, context: Context) {
        uiView.applyToEnclosingScrollView()
    }

    public final class FinderView: UIView {
        override public init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override public func didMoveToWindow() {
            super.didMoveToWindow()
            applyToEnclosingScrollView()
        }

        func applyToEnclosingScrollView() {
            var view = superview
            while let current = view {
                if let scrollView = current as? UIScrollView {
                    scrollView.bounces = false
                    return
                }
                view = current.superview
            }
        }
    }
}
