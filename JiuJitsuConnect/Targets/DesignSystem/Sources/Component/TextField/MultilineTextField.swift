//
//  MultilineTextField.swift
//  DesignSystem
//
//  줄바꿈되는 단일 값 입력 필드(닉네임·도장명 등 "표시형" 입력).
//
//  SwiftUI `TextField(axis: .vertical)`는 소프트웨어 키보드 Return이 개행으로 바인딩에 들어온 뒤에야
//  개입할 수 있어 "개행 삽입 → 제거"가 한 프레임 보인다. UITextView는 `shouldChangeTextIn`에서
//  개행 삽입 자체를 거부할 수 있으므로 UIKit으로 감싸고, Return은 `onSubmit`으로만 전달한다.
//

import SwiftUI
import UIKit

public struct MultilineTextField: UIViewRepresentable {

    @Binding private var text: String
    @Binding private var isFocused: Bool
    private let font: UIFont
    private let textColor: Color
    private let tintColor: Color
    private let textAlignment: NSTextAlignment
    private let onSubmit: () -> Void

    public init(
        text: Binding<String>,
        isFocused: Binding<Bool>,
        font: UIFont,
        textColor: Color,
        tintColor: Color,
        textAlignment: NSTextAlignment = .center,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self.font = font
        self.textColor = textColor
        self.tintColor = tintColor
        self.textAlignment = textAlignment
        self.onSubmit = onSubmit
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> FocusableTextView {
        let view = FocusableTextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        // 높이는 sizeThatFits로 SwiftUI에 맞추고, 내부 스크롤은 쓰지 않는다.
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.returnKeyType = .done
        view.text = text
        return view
    }

    public func updateUIView(_ uiView: FocusableTextView, context: Context) {
        context.coordinator.parent = self
        // 한글 조합 중 같은 값을 되쓰면 조합이 끊기므로 실제로 다를 때만 반영한다.
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = UIColor(textColor)
        uiView.tintColor = UIColor(tintColor)
        uiView.textAlignment = textAlignment
        uiView.wantsFocus = isFocused
        syncFocus(uiView)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: FocusableTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: height)
    }

    private func syncFocus(_ uiView: FocusableTextView) {
        if isFocused, !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.focusIfNeeded() }
        } else if !isFocused, uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        }
    }
}

// MARK: - Coordinator
public extension MultilineTextField {

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextField

        init(parent: MultilineTextField) {
            self.parent = parent
        }

        public func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            guard replacement.contains("\n") else { return true }

            // Return 키: 개행을 넣지 않고 확인 처리로 넘긴다.
            if replacement == "\n" {
                parent.onSubmit()
                return false
            }

            // 붙여넣기 등으로 개행이 섞여 들어오면 개행만 제거해서 반영한다.
            let sanitized = replacement.replacingOccurrences(of: "\n", with: "")
            if let current = textView.text,
               let textRange = Range(range, in: current) {
                textView.text = current.replacingCharacters(in: textRange, with: sanitized)
                textViewDidChange(textView)
            }
            return false
        }

        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        public func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        public func textViewDidEndEditing(_ textView: UITextView) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }
    }
}

// MARK: - FocusableTextView
/// SwiftUI 바인딩의 포커스 요청을 UIKit firstResponder로 옮기는 뷰.
/// window에 붙기 전 `becomeFirstResponder`는 실패하므로 붙는 시점에 다시 시도한다.
public final class FocusableTextView: UITextView {
    var wantsFocus = false

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            focusIfNeeded()
        }
    }

    func focusIfNeeded() {
        guard wantsFocus, !isFirstResponder, window != nil else { return }

        // push 전환 도중 firstResponder가 되면 키보드가 화면 전환 애니메이션에 묶여 옆에서 들어오므로,
        // 진행 중인 전환이 있으면 끝난 뒤(키보드는 아래에서 위로) 포커스한다.
        guard let coordinator = owningViewController?.transitionCoordinator else {
            becomeFirstResponder()
            return
        }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self, self.wantsFocus, !self.isFirstResponder else { return }
            self.becomeFirstResponder()
        }
    }

    private var owningViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}
