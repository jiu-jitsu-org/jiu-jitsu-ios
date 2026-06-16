//
//  WebPullToRefresh.swift
//  Presentation
//
//  BridgeWebView(커뮤니티 리스트)용 커스텀 풀다운 리프레시.
//  시스템 UIRefreshControl(단색 스피너)로는 디자인의 "연파랑 밴드 + 회전 아이콘/문구 →
//  완료 시 '오쓰! 최신 소식을 가져왔어요 🤙' 안내"를 표현할 수 없어 직접 구성한다.
//
//  밴드는 순수 UIKit UIView(WebPullToRefreshBand)로 그린다. WKWebView 스크롤뷰 내부에
//  UIHostingController를 부모 VC 없이 얹으면 사이즈(intrinsicContentSize)·라이프사이클이 불안정해
//  프레임이 무시되므로, 프레임을 100% 코드로 제어할 수 있는 UIKit 뷰로 둔다.
//
//  UX: 당기면 밴드가 손가락을 따라 최대 192pt까지 늘어나고, 임계값을 넘겨 손을 떼면 로딩 높이로
//  안착해 아이콘을 로딩 인디케이터처럼 연속 회전시킨다(데이터 fetch 중). 완료되면 안내 문구를
//  잠깐 보였다가 자동으로 접힌다.
//

import SwiftUI
import UIKit
import DesignSystem

/// 풀다운 리프레시 진행 단계.
enum WebRefreshPhase: Equatable {
    case idle        // 평상시(밴드 화면 밖)
    case pulling     // 사용자가 당기는 중
    case refreshing  // reload 진행 중(아이콘 연속 회전)
    case success     // reload 완료 안내 문구 노출
}

/// 오버스크롤 영역에 노출되는 연파랑 밴드. 단계에 따라 새로고침 안내/완료 안내를 그린다.
@MainActor
final class WebPullToRefreshBand: UIView {
    private enum Metrics {
        static let iconSize: CGFloat = 24
        static let iconTextSpacing: CGFloat = 10
    }
    private enum Strings {
        static let pulling = "새로고침"
        static let success = "오쓰! 최신 소식을 가져왔어요 🤙"
    }

    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let label = UILabel()
    private var isSpinning = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 디자인 가이드: 배경 Color/Blue/50, 글자·아이콘 Color/Blue/500
        backgroundColor = UIColor(Color.semantic.surface.primarySubtle)
        clipsToBounds = true
        // 밴드는 표시 전용 — 터치를 가로채 웹 스크롤을 방해하지 않게 한다.
        isUserInteractionEnabled = false

        let tint = UIColor(Color.semantic.primary.primary)
        iconView.image = UIImage(
            systemName: "arrow.clockwise",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        )
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        label.font = .pretendard.bodyM
        label.textColor = tint
        label.text = Strings.pulling

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Metrics.iconTextSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Metrics.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Metrics.iconSize),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 단계/당김 진행도에 맞춰 표시를 갱신한다.
    func update(phase: WebRefreshPhase, progress: CGFloat) {
        switch phase {
        case .success:
            stopSpinning()
            iconView.isHidden = true
            iconView.transform = .identity
            label.text = Strings.success
        case .refreshing:
            iconView.isHidden = false
            label.text = Strings.pulling
            startSpinning()
        case .idle, .pulling:
            stopSpinning()
            iconView.isHidden = false
            label.text = Strings.pulling
            // 당기는 정도만큼 아이콘을 돌려 진행 피드백을 준다(최대 270°).
            iconView.transform = CGAffineTransform(rotationAngle: progress * .pi * 1.5)
        }
    }

    // MARK: - 아이콘 연속 회전(로딩 인디케이터)

    private func startSpinning() {
        guard !isSpinning else { return }
        isSpinning = true
        iconView.transform = .identity
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 0.8
        rotation.repeatCount = .infinity
        iconView.layer.add(rotation, forKey: "ptr.spin")
    }

    private func stopSpinning() {
        guard isSpinning else { return }
        isSpinning = false
        iconView.layer.removeAnimation(forKey: "ptr.spin")
    }
}

/// WKWebView 스크롤뷰에 커스텀 풀다운 리프레시를 부착하고 단계 전환을 관리하는 컨트롤러.
@MainActor
final class WebPullToRefreshController {
    private enum Metrics {
        // 당길 때 밴드가 늘어나는 최대 높이.
        static let maxHeight: CGFloat = 192
        // 이 거리 이상 당긴 뒤 손을 떼면 리프레시가 발동한다.
        static let triggerThreshold: CGFloat = 80
        // reload 진행 중 밴드가 안착해 머무는 높이(로딩 인디케이터 노출).
        static let refreshingHeight: CGFloat = 80
    }
    private enum Timing {
        static let insetAnimation: TimeInterval = 0.3
        // 완료 안내 문구 노출 시간.
        static let successDisplay: Duration = .milliseconds(800)
    }

    private weak var scrollView: UIScrollView?
    private let band = WebPullToRefreshBand()
    private let onRefresh: () -> Void
    private var phase: WebRefreshPhase = .idle
    // 완료 안내 노출 후 밴드를 닫는 지연 작업. 새 리프레시가 시작되면 취소한다.
    private var collapseTask: Task<Void, Never>?
    // 인셋/프레임을 코드로 애니메이션하는 동안에는 스크롤 콜백이 밴드 높이를 덮어쓰지 않게 한다.
    private var isAdjustingInset = false

    init(scrollView: UIScrollView, onRefresh: @escaping () -> Void) {
        self.scrollView = scrollView
        self.onRefresh = onRefresh
        // 콘텐츠 원점(0) 바로 위에 두어, 오버스크롤 시에만 보이게 한다.
        scrollView.addSubview(band)
        layoutBand(height: 0)
        enforceVerticalBounce()
    }

    /// 웹이 `overscroll-behavior: none`로 바운스를 꺼두면 상단 오버스크롤이 생기지 않아
    /// 풀다운 자체가 불가능하다. 네이티브 스크롤뷰의 세로 바운스를 강제로 켜 풀다운 여지를 만든다.
    /// (웹 로드/레이아웃 후 WebKit이 다시 끌 수 있어 didFinish에서 재적용한다.)
    func enforceVerticalBounce() {
        scrollView?.bounces = true
        scrollView?.alwaysBounceVertical = true
    }

    // MARK: - UIScrollViewDelegate 포워딩(BridgeWebView.Coordinator에서 호출)

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 코드 애니메이션 중에는 그쪽이 프레임을 책임진다.
        guard !isAdjustingInset else { return }
        switch phase {
        case .refreshing, .success:
            // 인셋으로 고정 노출 중 — 높이를 유지한다.
            layoutBand(height: Metrics.refreshingHeight)
        case .idle, .pulling:
            let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
            // 밴드는 손가락을 따라 최대 192까지 늘어난다.
            layoutBand(height: max(0, min(pull, Metrics.maxHeight)))
            phase = pull > 0 ? .pulling : .idle
            band.update(phase: phase, progress: max(0, min(1, pull / Metrics.triggerThreshold)))
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        guard phase == .pulling else { return }
        let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        if pull >= Metrics.triggerThreshold {
            beginRefreshing()
        } else {
            // 임계값 미달 — idle로 되돌리고, 러버밴드 복귀(scrollViewDidScroll)가 0으로 줄인다.
            phase = .idle
        }
    }

    // MARK: - 단계 전환

    private func beginRefreshing() {
        guard let scrollView else { return }
        collapseTask?.cancel()
        phase = .refreshing
        band.update(phase: .refreshing, progress: 1)
        // 로딩 높이로 안착시켜 reload 동안 밴드를 노출한다(콘텐츠를 그만큼 아래로 민다).
        isAdjustingInset = true
        UIView.animate(withDuration: Timing.insetAnimation) {
            scrollView.contentInset.top = Metrics.refreshingHeight
            self.layoutBand(height: Metrics.refreshingHeight)
        } completion: { [weak self] _ in
            self?.isAdjustingInset = false
        }
        onRefresh()
    }

    /// reload 종료 시 호출. 성공이면 완료 안내를 잠깐 보였다가, 실패면 즉시 밴드를 닫는다.
    func finishRefreshing(success: Bool) {
        guard phase == .refreshing else { return }
        guard success else {
            collapse()
            return
        }
        phase = .success
        band.update(phase: .success, progress: 1)
        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: Timing.successDisplay)
            guard !Task.isCancelled else { return }
            self?.collapse()
        }
    }

    private func collapse() {
        guard let scrollView else { return }
        // 접히는 동안 현재 문구(완료/새로고침)를 유지하다가, 끝난 뒤 idle로 되돌린다.
        isAdjustingInset = true
        UIView.animate(withDuration: Timing.insetAnimation) {
            scrollView.contentInset.top = 0
            self.layoutBand(height: 0)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isAdjustingInset = false
            self.phase = .idle
            self.band.update(phase: .idle, progress: 0)
        }
    }

    // 콘텐츠 원점 바로 위에 밴드를 가로 꽉 차게, 주어진 높이로 배치한다(바닥을 원점에 고정).
    private func layoutBand(height: CGFloat) {
        guard let scrollView else { return }
        band.frame = CGRect(x: 0, y: -height, width: scrollView.bounds.width, height: height)
    }
}
