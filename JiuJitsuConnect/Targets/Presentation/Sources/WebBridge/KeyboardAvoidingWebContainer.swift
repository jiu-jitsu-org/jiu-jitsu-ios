//
//  KeyboardAvoidingWebContainer.swift
//  Presentation
//
//  BridgeWebView가 웹뷰를 감싸는 컨테이너. 키보드만큼 웹뷰 높이를 줄이고, 탭 바가 가린 영역을 웹에 알린다.
//

import UIKit
import WebKit

/// 키보드가 뜨면 웹뷰 프레임을 키보드 상단까지 줄이고, 내리면 화면 바닥까지 복귀시키는 컨테이너.
///
/// 웹뷰 프레임을 키보드만큼 줄이면 웹의 100dvh/고정 셸이 키보드 위 영역으로 맞춰져 입력바가
/// 키보드 위에 붙고 헤더는 고정된다. `keyboardLayoutGuide.topAnchor`에만 묶으면 키보드 해제 후
/// 가이드가 하단 safe area만큼 위에 머물러 흰 여백이 남으므로, 가이드 제약은 항상 살려두되
/// (키보드 추적 + 위로 띄움) required보다 한 단계 낮추고, 키보드가 없을 때만 바닥 고정 제약
/// (required)을 켜서 강제 복귀시킨다.
final class KeyboardAvoidingWebContainer: UIView {
    private var bottomToBottomEdge: NSLayoutConstraint?
    private weak var webView: WKWebView?
    private var offsetObservation: NSKeyValueObservation?
    // 켜면 떠 있는 탭 바 자리(tabBarObscuredBottom)를 웹뷰가 가려진 영역으로 알린다(#267).
    var reportsTabBarAsObscured = false
    // 화면 바닥에서 탭 바 윗변까지(AppTabView가 환경값으로 건넴, #284). 아래 안전 영역은 SwiftUI의
    // `.safeAreaInset`이 넘어오지 않아 기기 홈 막대 자리(34)뿐이라 쓰지 않는다. 탭 바가 숨어도 같은 값이라
    // 웹의 글쓰기 버튼·마지막 글이 탭 바와 함께 들썩이지 않는다(움직이는 건 탭 바 하나).
    var tabBarObscuredBottom: CGFloat = 0 {
        didSet { if reportsTabBarAsObscured, oldValue != tabBarObscuredBottom { setNeedsLayout() } }
    }
    // 웹 바텀 시트가 떠 있는지(#314). 떠 있으면 탭 바가 숨으므로 가린 영역이 없다 — 시트·딤이 화면 맨 아래까지 온다.
    var isSheetOpen = false {
        didSet { if reportsTabBarAsObscured, oldValue != isSheetOpen { setNeedsLayout() } }
    }
    // 켜면 웹뷰를 탭 첫 화면 머리줄(상태바 + 44) 뒤까지 그리고, 머리줄에 가린 높이를 웹뷰가 가려진 영역으로 알린다.
    // 웹은 그 아래부터 배치되고(고정·sticky 요소 포함), 스크롤하면 글이 머리줄 뒤로 지나가며 비친다.
    var extendsUnderTabHeader = false {
        didSet {
            guard oldValue != extendsUnderTabHeader else { return }
            // 가린 곳에 시스템이 까는 위쪽 가장자리 효과(맨 위 고정 · sticky 줄 색으로 채우는 면)를 끈다 —
            // 켜 두면 웹이 머리줄 뒤로 늘여 그린 유리 면을 덮어, 머리줄 아래 끝에 경계가 생긴다.
            webView?.scrollView.topEdgeEffect.isHidden = extendsUnderTabHeader
            setNeedsLayout()
        }
    }
    // 머리줄에 가린 높이가 바뀌면 부른다. 콘텐츠 위쪽 여백은 당겨서 새로고침과 함께 다뤄야 해서 코디네이터가 맡는다.
    var onHeaderObscuredTopChanged: ((CGFloat) -> Void)?
    private var appliedHeaderObscuredTop: CGFloat = 0
    // 스크롤할 때마다 부른다(탭 첫 화면 웹만, #267).
    var onScroll: (@MainActor (CGFloat, CGFloat, Bool) -> Void)?
    // 키보드가 떠 있는지. 고정 셸(상세)이 댓글을 쓰는 중에 당겨서 새로고침되지 않게 본다(#432).
    private(set) var isKeyboardVisible = false
    // 키보드가 뜨고 내릴 때 알린다. 상세는 이 동안 보고 있는 글의 푸시로 다시 불러오지 않는다 —
    // 다시 불러오면 답글 대상이 사라져 쓰던 답글이 일반 댓글로 올라간다(#383).
    var onKeyboardVisibilityChanged: ((Bool) -> Void)?

    func pinWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.scrollView.topEdgeEffect.isHidden = extendsUnderTabHeader
        offsetObservation = webView.scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            MainActor.assumeIsolated { self?.reportScroll(of: scrollView) }
        }
        // 키보드가 떠 있는 동안 가이드가 키보드만 추적하도록(하단 safe area 미포함) 한다.
        keyboardLayoutGuide.usesBottomSafeArea = false
        // 항상 활성 → ① 가이드가 키보드를 추적하도록 engage ② 키보드 위로 웹뷰를 띄움.
        //   required보다 낮춰, 키보드 없을 때 아래 바닥 제약이 우선하게 한다.
        let toKeyboard = webView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        toKeyboard.priority = UILayoutPriority(999)
        // 키보드가 없을 때만 켜서 웹뷰를 화면 바닥까지 강제 복귀(잔류 여백 제거).
        let toBottomEdge = webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomToBottomEdge = toBottomEdge
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toKeyboard
        ])
    }

    // 키보드를 올린 채 위에 다른 화면이 쌓이면, 키보드는 이 뷰가 창에서 떨어진 뒤에 내려가 가이드가 그걸 못 받는다.
    // 돌아왔을 때 가이드가 옛 키보드 자리에 남아 웹뷰가 줄어든 채 머무르므로, 떨어지기 전에 포커스를 풀어 둔다(#327).
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard newWindow == nil else { return }
        webView?.endEditing(true)
    }

    // 창 밖에 있던 사이 키보드가 바뀌었을 수 있으니, 다시 보일 때 바닥 고정 여부를 곧바로 다시 정한다(#327).
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 가이드 상단이 하단 safe area보다 충분히 위에 있으면 키보드가 실제로 떠 있는 것으로 본다.
        // 키보드 ↑이면 바닥 고정을 풀어 웹뷰가 키보드 위로 따라 올라가게 하고,
        // 키보드 ↓이면 바닥 고정을 켜서 잔류 여백 없이 복귀시킨다.
        let distanceFromBottom = bounds.maxY - keyboardLayoutGuide.layoutFrame.minY
        // 탭 첫 화면은 떠 있는 탭 바 자리만큼 아래 안전 영역이 커져 있어(#267), 기기 자체의 아래 안전 영역과 견준다.
        let deviceBottomInset = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
        let keyboardVisible = distanceFromBottom > deviceBottomInset + 8
        if isKeyboardVisible != keyboardVisible, onKeyboardVisibilityChanged != nil {
            // 레이아웃 도중에 상태를 바꾸면 SwiftUI 갱신과 겹치므로 다음 차례로 미룬다.
            DispatchQueue.main.async { [weak self] in self?.onKeyboardVisibilityChanged?(keyboardVisible) }
        }
        isKeyboardVisible = keyboardVisible
        // 가린 영역을 알리는 웹뷰만 건드린다 — 상세 웹뷰는 WebKit 기본값(스크롤 뷰 여백)을 그대로 쓴다.
        if reportsTabBarAsObscured || extendsUnderTabHeader, let webView {
            let obscuredTop = ProcessInfo.processInfo.arguments.contains("-CAPTURE_NOOBSCURE") ? 0 : headerObscuredTop // CAPTURE-TEMP
            let restingTop = headerObscuredTop
            let obscuredBottom = reportsTabBarAsObscured && !keyboardVisible && !isSheetOpen ? tabBarObscuredBottom : 0
            if webView.obscuredContentInsets.top != obscuredTop || webView.obscuredContentInsets.bottom != obscuredBottom {
                webView.obscuredContentInsets = UIEdgeInsets(top: obscuredTop, left: 0, bottom: obscuredBottom, right: 0)
                webView.scrollView.verticalScrollIndicatorInsets.top = obscuredTop
                webView.scrollView.verticalScrollIndicatorInsets.bottom = obscuredBottom
                // 웹에 알리는 안전 영역(ChromelessWebView)은 가린 곳 아래부터 다시 잰다.
                webView.setNeedsLayout()
            }
            if appliedHeaderObscuredTop != restingTop {
                appliedHeaderObscuredTop = restingTop
                onHeaderObscuredTopChanged?(restingTop)
            }
        }
        let shouldPinBottom = !keyboardVisible
        guard bottomToBottomEdge?.isActive != shouldPinBottom else { return }
        bottomToBottomEdge?.isActive = shouldPinBottom
    }

    // 화면 맨 위에서 머리줄 아래 끝까지 중 이 뷰와 겹치는 높이. 세로 고정 앱이라 상태바 높이는 기기마다 정해져 있다.
    private var headerObscuredTop: CGFloat {
        guard extendsUnderTabHeader, let window else { return 0 }
        let headerBottom = window.safeAreaInsets.top + WebSafeAreaInsets.tabHeaderHeight
        return max(headerBottom - convert(bounds, to: window).minY, 0).rounded()
    }

    private func reportScroll(of scrollView: UIScrollView) {
        guard let onScroll else { return }
        let inset = scrollView.adjustedContentInset
        let offsetY = scrollView.contentOffset.y + inset.top
        let maxOffsetY = scrollView.contentSize.height + inset.top + inset.bottom - scrollView.bounds.height
        let isUserScrolling = scrollView.isTracking || scrollView.isDecelerating
        onScroll(offsetY, maxOffsetY, isUserScrolling)
    }
}
