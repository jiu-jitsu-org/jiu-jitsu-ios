//
//  WebPullToRefresh.swift
//  Presentation
//
//  BridgeWebView(커뮤니티 리스트)용 커스텀 풀다운 리프레시.
//  시스템 UIRefreshControl(단색 스피너)로는 디자인의 "연파랑 밴드 + 샤카 손/랜덤 멘트 →
//  놓으면 샤카 손이 팡 터짐 → 완료 시 '오쓰! 최신 소식을 가져왔어요' 안내"를 표현할 수 없어 직접 구성한다.
//
//  밴드는 순수 UIKit UIView(WebPullToRefreshBand)로 그린다. WKWebView 스크롤뷰 내부에
//  UIHostingController를 부모 VC 없이 얹으면 사이즈(intrinsicContentSize)·라이프사이클이 불안정해
//  프레임이 무시되므로, 프레임을 100% 코드로 제어할 수 있는 UIKit 뷰로 둔다.
//
//  UX: 당기면 밴드가 손가락을 따라 최대 192pt까지 늘어나고, 임계값을 넘기면 "놓으면 OSS!"로 바뀌며
//  가볍게 진동한다. 손을 떼면 화면 가운데에서 띠 색 샤카 손이 사방으로 터지고, 밴드는 로딩 높이로
//  안착해 손 아이콘을 흔든다(데이터 fetch 중). 완료되면 안내 문구를 잠깐 보였다가 자동으로 접힌다.
//

import SwiftUI
import UIKit
import DesignSystem

/// 풀다운 리프레시 진행 단계.
enum WebRefreshPhase: Equatable {
    case idle        // 평상시(밴드 화면 밖)
    case pulling     // 사용자가 당기는 중
    case refreshing  // reload 진행 중(손 아이콘 흔들기)
    case success     // reload 완료 안내 문구 노출
}

/// 오버스크롤 영역에 노출되는 연파랑 밴드. 단계에 따라 랜덤 멘트/완료 안내를 그린다.
@MainActor
final class WebPullToRefreshBand: UIView {
    private enum Metrics {
        static let iconSize: CGFloat = 26
        static let iconTextSpacing: CGFloat = 10
        // 문구가 손 아이콘보다 조금 늦게(밴드가 이만큼 열린 뒤) 떠오른다.
        static let labelFadeStart: CGFloat = 24
        static let labelFadeLength: CGFloat = 32
    }
    private enum Strings {
        // 당길 때마다 하나를 골라 보여 준다.
        static let pullingLines = [
            "OSS! 새 글 스윕 중",
            "샤카~ 오늘도 매트 위로",
            "탭 치기 전에 새로고침",
            "롤링 한 판 더 불러오는 중",
            "가드 다시 세우는 중",
            "숨 고르고, OSS",
            "띠 꽉 묶고 불러올게요",
            "오늘 수련 후기 도착 중"
        ]
        static let armed = "놓으면 OSS!"
        static let success = "오쓰! 최신 소식을 가져왔어요"
    }

    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let label = UILabel()
    private var isWaving = false
    private var pullingLine = Strings.pullingLines[0]
    // 문구 투명도 계산용. 컨트롤러가 밴드를 늘릴 때와 같은 기준이다.
    private let triggerThreshold: CGFloat

    init(triggerThreshold: CGFloat) {
        self.triggerThreshold = triggerThreshold
        super.init(frame: .zero)
        // 디자인 가이드: 배경 Color/Blue/50, 글자·아이콘 Color/Blue/500
        backgroundColor = UIColor(Color.semantic.surface.primarySubtle)
        clipsToBounds = true
        // 밴드는 표시 전용 — 터치를 가로채 웹 스크롤을 방해하지 않게 한다.
        isUserInteractionEnabled = false

        let tint = UIColor(Color.semantic.primary.primary)
        // 디자인: 광택 있는 파란 샤카 손(OSS 브랜딩). 당길수록 커지며 바로 서고, 로딩 중엔 흔든다.
        iconView.image = Assets.Common.Shaka.icon.image
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        label.font = .pretendard.bodyM
        label.textColor = tint
        label.text = pullingLine

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

    /// 새 당김이 시작될 때 이번에 보여 줄 멘트를 고른다.
    func prepareNewPull() {
        pullingLine = Strings.pullingLines.randomElement() ?? pullingLine
    }

    /// 단계/당김 진행도에 맞춰 표시를 갱신한다.
    func update(phase: WebRefreshPhase, progress: CGFloat) {
        switch phase {
        case .success:
            stopWaving()
            iconView.isHidden = true
            iconView.transform = .identity
            label.alpha = 1
            label.text = Strings.success
        case .refreshing:
            iconView.isHidden = false
            iconView.alpha = 1
            iconView.transform = .identity
            label.alpha = 1
            label.text = pullingLine
            startWaving()
        case .idle, .pulling:
            stopWaving()
            iconView.isHidden = false
            // 당기는 정도만큼 손이 커지며(0.6→1) 기울어진 채 바로 선다(-20°→0°).
            let scale = 0.6 + 0.4 * progress
            iconView.transform = CGAffineTransform(rotationAngle: (-20 + 20 * progress) * .pi / 180)
                .scaledBy(x: scale, y: scale)
            iconView.alpha = progress
            let opened = progress * triggerThreshold
            label.alpha = min(1, max(0, (opened - Metrics.labelFadeStart) / Metrics.labelFadeLength))
            label.text = progress >= 1 ? Strings.armed : pullingLine
        }
    }

    // MARK: - 손 아이콘 튕김 + 흔들기(로딩 인디케이터)

    private func startWaving() {
        guard !isWaving else { return }
        isWaving = true
        // 놓는 순간 한 번 크게 튕긴다.
        let pop = CAKeyframeAnimation(keyPath: "transform")
        pop.values = [
            CATransform3DIdentity,
            CATransform3DRotate(CATransform3DMakeScale(1.45, 1.45, 1), -18 * .pi / 180, 0, 0, 1),
            CATransform3DIdentity
        ]
        pop.keyTimes = [0, 0.4, 1]
        pop.duration = 0.42
        pop.timingFunctions = [
            CAMediaTimingFunction(controlPoints: 0.3, 1.6, 0.4, 1),
            CAMediaTimingFunction(name: .easeOut)
        ]
        iconView.layer.add(pop, forKey: "ptr.pop")
        // 이어서 불러오는 동안 까딱까딱 흔든다.
        let wave = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wave.values = [0.0, -16 * Double.pi / 180, 0.0]
        wave.duration = 0.5
        wave.beginTime = CACurrentMediaTime() + 0.42
        wave.repeatCount = .infinity
        wave.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconView.layer.add(wave, forKey: "ptr.wave")
    }

    private func stopWaving() {
        guard isWaving else { return }
        isWaving = false
        iconView.layer.removeAnimation(forKey: "ptr.pop")
        iconView.layer.removeAnimation(forKey: "ptr.wave")
    }
}

/// 새로고침이 발동할 때 화면 가운데에서 띠 색 샤카 손을 사방으로 '팡' 터뜨리는 표시 전용 뷰.
///
/// 손마다 방향·속도·출발 시점을 흩어 고리처럼 모이지 않게 한다. 처음엔 빠르게 튀었다가 공기 저항으로
/// 금방 느려진 뒤 떨어지며 사라진다. 물리는 60fps 기준 프레임 수로 환산해 120Hz 화면에서도 같은 빠르기다.
@MainActor
final class ShakaBurstView: UIView {
    private enum Physics {
        static let count = 12
        static let reducedCount = 4
        static let drag: CGFloat = 0.93
        static let gravity: CGFloat = 0.32
        // 이미지에 그림자 여백이 포함돼 있어, 손 크기에 이 비율을 곱해 그린다.
        static let shadowPadding: CGFloat = 1.25
    }

    private struct Particle {
        let layer: CALayer
        let size: CGFloat
        let aspect: CGFloat
        let flip: CGFloat
        let maxLife: CGFloat
        var position: CGPoint
        var velocity: CGVector
        var rotation: CGFloat
        let spin: CGFloat
        var life: CGFloat = 0
        var wait: CGFloat
    }

    private let images: [UIImage] = [
        Assets.Common.Shaka.burstWhite.image,
        Assets.Common.Shaka.burstBlue.image,
        Assets.Common.Shaka.burstPurple.image,
        Assets.Common.Shaka.burstBrown.image,
        Assets.Common.Shaka.burstBlack.image
    ]
    private var particles: [Particle] = []
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func burst(at origin: CGPoint) {
        // 움직임 줄이기: 몇 개만 제자리에서 나타났다 사라진다.
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let count = reduceMotion ? Physics.reducedCount : Physics.count
        for _ in 0..<count {
            guard let image = images.randomElement() else { return }
            // 위쪽 위주로 넓게(±153°) 흩는다.
            let angle = -CGFloat.pi / 2 + CGFloat.random(in: -0.5...0.5) * .pi * 1.7
            let speed = reduceMotion ? 0 : CGFloat.random(in: 5...21)
            let item = CALayer()
            item.contents = image.cgImage
            item.contentsScale = image.scale
            item.contentsGravity = .resizeAspect
            item.opacity = 0
            layer.addSublayer(item)
            particles.append(Particle(
                layer: item,
                size: CGFloat.random(in: 18...34),
                aspect: image.size.height / image.size.width,
                flip: Bool.random() ? -1 : 1,
                maxLife: CGFloat.random(in: 60...90),
                position: CGPoint(
                    x: origin.x + CGFloat.random(in: -8...8),
                    y: origin.y + CGFloat.random(in: -5...5)
                ),
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed * 0.75),
                rotation: CGFloat.random(in: -0.4...0.4),
                spin: CGFloat.random(in: -0.125...0.125),
                wait: CGFloat.random(in: 0...6)
            ))
        }
        guard displayLink == nil else { return }
        lastTimestamp = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func step(_ link: CADisplayLink) {
        let frames = CGFloat(min((link.timestamp - lastTimestamp) / (1.0 / 60.0), 3))
        lastTimestamp = link.timestamp

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for index in particles.indices {
            var item = particles[index]
            defer { particles[index] = item }
            if item.wait > 0 {
                item.wait -= frames
                continue
            }
            item.life += frames
            let drag = pow(Physics.drag, frames)
            item.velocity.dx *= drag
            item.velocity.dy = item.velocity.dy * drag + Physics.gravity * frames
            item.position.x += item.velocity.dx * frames
            item.position.y += item.velocity.dy * frames
            item.rotation += item.spin * frames

            let progress = item.life / item.maxLife
            // 작게 나왔다가 1.3배로 커진 뒤 제 크기로 돌아온다.
            let pop: CGFloat = progress < 0.08
                ? 0.3 + progress / 0.08
                : progress < 0.2 ? 1.3 - (progress - 0.08) / 0.12 * 0.3 : 1
            // 0 아래로 내려가지 않게 막는다(음수면 마지막 프레임에 진하게 반짝인다).
            let alpha = max(0, progress > 0.55 ? 1 - (progress - 0.55) / 0.45 : 1)

            let width = item.size * pop * Physics.shadowPadding
            item.layer.bounds = CGRect(x: 0, y: 0, width: width, height: width * item.aspect)
            item.layer.position = item.position
            item.layer.setAffineTransform(CGAffineTransform(rotationAngle: item.rotation).scaledBy(x: item.flip, y: 1))
            item.layer.opacity = Float(alpha)
        }
        CATransaction.commit()

        for item in particles where item.life >= item.maxLife {
            item.layer.removeFromSuperlayer()
        }
        particles.removeAll { $0.life >= $0.maxLife }
        if particles.isEmpty {
            displayLink?.invalidate()
            displayLink = nil
        }
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
    private let band = WebPullToRefreshBand(triggerThreshold: Metrics.triggerThreshold)
    // 웹뷰 위에 얹는 터짐 효과. 스크롤과 함께 움직이지 않게 스크롤뷰 바깥(웹뷰)에 둔다.
    private let burstView = ShakaBurstView()
    private let armedFeedback = UIImpactFeedbackGenerator(style: .light)
    // 임계값을 넘겨 "놓으면 OSS!" 상태인지. 넘는 순간 한 번만 진동한다.
    private var isArmed = false
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
            if phase == .idle, pull > 0 {
                band.prepareNewPull()
                armedFeedback.prepare()
            }
            phase = pull > 0 ? .pulling : .idle
            // 손을 뗀 뒤 되돌아가는 중엔 진동하지 않는다.
            let armed = pull >= Metrics.triggerThreshold
            if armed, !isArmed, scrollView.isTracking {
                armedFeedback.impactOccurred()
            }
            isArmed = armed
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
        burst(in: scrollView)
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

    /// 밴드가 안착할 자리(로딩 높이 띠)의 한가운데에서 손을 터뜨린다.
    private func burst(in scrollView: UIScrollView) {
        guard let host = scrollView.superview else { return }
        if burstView.superview !== host {
            burstView.frame = host.bounds
            burstView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            host.addSubview(burstView)
        }
        host.bringSubviewToFront(burstView)
        // 안전 영역 등 우리가 넣지 않은 위쪽 여백 아래부터 밴드가 시작된다.
        let systemTop = scrollView.adjustedContentInset.top - scrollView.contentInset.top
        let origin = CGPoint(
            x: scrollView.frame.midX,
            y: scrollView.frame.minY + systemTop + Metrics.refreshingHeight / 2
        )
        burstView.burst(at: origin)
    }

    // 콘텐츠 원점 바로 위에 밴드를 가로 꽉 차게, 주어진 높이로 배치한다(바닥을 원점에 고정).
    private func layoutBand(height: CGFloat) {
        guard let scrollView else { return }
        band.frame = CGRect(x: 0, y: -height, width: scrollView.bounds.width, height: height)
    }
}
