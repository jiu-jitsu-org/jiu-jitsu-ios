//
//  WebPullToRefresh.swift
//  Presentation
//
//  BridgeWebView(커뮤니티 리스트)용 커스텀 풀다운 리프레시.
//  시스템 UIRefreshControl(단색 스피너)로는 디자인의 "연파랑 밴드 + 회전 아이콘/문구 →
//  완료 시 '오쓰! 최신 소식을 가져왔어요 🤙' 안내"를 표현할 수 없어, 밴드 UI는 SwiftUI로 그리고
//  당김/노출은 WKWebView 스크롤뷰의 contentInset·서브뷰 프레임으로 직접 제어한다.
//
//  UX: 당기면 밴드가 손가락을 따라 최대 192pt까지 늘어나고, 임계값을 넘겨 손을 떼면 로딩 높이로
//  안착해 아이콘을 로딩 인디케이터처럼 연속 회전시킨다(데이터 fetch 중). 완료되면 안내 문구를
//  잠깐 보였다가 자동으로 접힌다.
//

import SwiftUI
import UIKit
import DesignSystem

/// 풀다운 리프레시 진행 단계. View(밴드)와 컨트롤러가 공유한다.
enum WebRefreshPhase: Equatable {
    case idle        // 평상시(밴드 화면 밖)
    case pulling     // 사용자가 당기는 중
    case refreshing  // reload 진행 중(아이콘 연속 회전)
    case success     // reload 완료 안내 문구 노출
}

/// 밴드 SwiftUI View가 관찰하는 상태. 스크롤 콜백(메인)에서만 갱신한다.
@MainActor
@Observable
final class WebRefreshModel {
    var phase: WebRefreshPhase = .idle
    // 당기는 정도(0...1). pulling 동안 아이콘 회전 피드백에 쓴다.
    var pullProgress: Double = 0
}

/// 오버스크롤 영역에 노출되는 연파랑 밴드. 단계에 따라 새로고침 안내/완료 안내를 그린다.
struct WebPullToRefreshHeader: View {
    let model: WebRefreshModel
    // refreshing 동안 아이콘을 연속 회전시키기 위한 토글.
    @State private var spinning = false

    private enum Metrics {
        static let iconSize: CGFloat = 24
        static let iconTextSpacing: CGFloat = 10
    }

    var body: some View {
        ZStack {
            // 디자인 가이드: 배경 Color/Blue/50
            Color.semantic.surface.primarySubtle
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onChange(of: model.phase) { _, phase in
            if phase == .refreshing {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    spinning = true
                }
            } else {
                spinning = false
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .success:
            // 디자인 가이드: 글자색 Color/Blue/500, 폰트 BodyM
            Text("오쓰! 최신 소식을 가져왔어요 🤙")
                .font(.pretendard.bodyM)
                .foregroundStyle(Color.semantic.primary.primary)
        default:
            HStack(spacing: Metrics.iconTextSpacing) {
                // 아이콘 24x24, 로딩 인디케이터처럼 회전. (브랜드 전용 에셋이 생기면 교체)
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(Color.semantic.primary.primary)
                    // 당기는 중에는 진행도만큼, refreshing 동안에는 연속 회전(두 회전이 합성된다).
                    .rotationEffect(.degrees(model.phase == .refreshing ? 0 : model.pullProgress * 270))
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                Text("새로고침")
                    .font(.pretendard.bodyM)
                    .foregroundStyle(Color.semantic.primary.primary)
            }
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
        static let triggerThreshold: CGFloat = 96
        // reload 진행 중 밴드가 안착해 머무는 높이(로딩 인디케이터 노출).
        static let refreshingHeight: CGFloat = 96
    }
    private enum Timing {
        static let insetAnimation: TimeInterval = 0.3
        // 완료 안내 문구 노출 시간.
        static let successDisplay: Duration = .milliseconds(800)
    }

    private weak var scrollView: UIScrollView?
    private let host: UIHostingController<WebPullToRefreshHeader>
    private let model = WebRefreshModel()
    private let onRefresh: () -> Void
    // 완료 안내 노출 후 밴드를 닫는 지연 작업. 새 리프레시가 시작되면 취소한다.
    private var collapseTask: Task<Void, Never>?
    // 인셋/프레임을 코드로 애니메이션하는 동안에는 스크롤 콜백이 밴드 높이를 덮어쓰지 않게 한다.
    private var isAdjustingInset = false

    init(scrollView: UIScrollView, onRefresh: @escaping () -> Void) {
        self.scrollView = scrollView
        self.onRefresh = onRefresh
        self.host = UIHostingController(rootView: WebPullToRefreshHeader(model: model))
        // 밴드 배경은 SwiftUI에서 그리므로 호스팅 뷰 자체는 투명하게 두고, 상단 safe area 보정도 끈다.
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        // 밴드는 표시 전용 — 터치를 가로채 웹 스크롤을 방해하지 않게 한다.
        host.view.isUserInteractionEnabled = false
        // 콘텐츠 원점(0) 바로 위에 두어, 오버스크롤 시에만 보이게 한다.
        scrollView.addSubview(host.view)
        layoutHeader(height: 0)
    }

    // MARK: - UIScrollViewDelegate 포워딩(BridgeWebView.Coordinator에서 호출)

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 코드 애니메이션 중에는 그쪽이 프레임을 책임진다.
        guard !isAdjustingInset else { return }
        switch model.phase {
        case .refreshing, .success:
            // 인셋으로 고정 노출 중 — 높이를 유지한다.
            layoutHeader(height: Metrics.refreshingHeight)
        case .idle, .pulling:
            let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
            // 밴드는 손가락을 따라 최대 192까지 늘어난다.
            layoutHeader(height: max(0, min(pull, Metrics.maxHeight)))
            model.pullProgress = max(0, min(1, pull / Metrics.triggerThreshold))
            model.phase = pull > 0 ? .pulling : .idle
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        guard model.phase == .pulling else { return }
        if model.pullProgress >= 1 {
            beginRefreshing()
        } else {
            // 임계값 미달 — 자연스러운 러버밴드 복귀에 맡기고 상태만 되돌린다.
            model.phase = .idle
            model.pullProgress = 0
        }
    }

    // MARK: - 단계 전환

    private func beginRefreshing() {
        guard let scrollView else { return }
        collapseTask?.cancel()
        model.phase = .refreshing
        // 로딩 높이로 안착시켜 reload 동안 밴드를 노출한다(콘텐츠를 그만큼 아래로 민다).
        isAdjustingInset = true
        UIView.animate(withDuration: Timing.insetAnimation) {
            scrollView.contentInset.top = Metrics.refreshingHeight
            self.layoutHeader(height: Metrics.refreshingHeight)
        } completion: { [weak self] _ in
            self?.isAdjustingInset = false
        }
        onRefresh()
    }

    /// reload 종료 시 호출. 성공이면 완료 안내를 잠깐 보였다가, 실패면 즉시 밴드를 닫는다.
    func finishRefreshing(success: Bool) {
        guard model.phase == .refreshing else { return }
        guard success else {
            collapse()
            return
        }
        model.phase = .success
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
            self.layoutHeader(height: 0)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isAdjustingInset = false
            self.model.phase = .idle
            self.model.pullProgress = 0
        }
    }

    // 콘텐츠 원점 바로 위에 밴드를 가로 꽉 차게, 주어진 높이로 배치한다(바닥을 원점에 고정).
    private func layoutHeader(height: CGFloat) {
        guard let scrollView else { return }
        host.view.frame = CGRect(x: 0, y: -height, width: scrollView.bounds.width, height: height)
    }
}
