//
//  ToastView.swift
//  DesignSystem
//
//  Created by suni on 9/22/25.
//

import SwiftUI
import CoreKit
import OSLog

/// 상태 아이콘이 있는 짙은 토스트 상자. 웹 토스트와 모양·움직임을 맞춘다.
///
/// - 최소 높이 58(여러 줄이면 늘어남) · 모서리 20 · 짙은 바탕 + 옅은 그림자
/// - 아이콘 20 ↔ 글자 12, 글자 ↔ 버튼 8
/// - 떠 있는 채로 다시 불리면 상자는 그대로, 아이콘·글자만 8 아래에서 올라오며 바뀐다(0.3초)
/// - 아래·옆으로 끌면 손가락을 따라오고, 충분히 밀고 놓으면 닫힌다
///
/// 화면에 붙일 때는 나타남·사라짐 움직임까지 들어 있는 `.toast(_:onSwipe:onButtonTapped:)`를 쓴다.
public struct ToastView: View {

    public init(state: ToastState,
                onSwipe: @escaping () -> Void,
                onButtonTapped: @escaping (ToastState.Action) -> Void) {
        self.state = state
        self.onSwipe = onSwipe
        self.onButtonTapped = onButtonTapped
    }

    let state: ToastState
    var onSwipe: () -> Void
    var onButtonTapped: (ToastState.Action) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 손가락으로 끄는 중인 거리. 놓으면 제자리로 돌아오거나 닫힌다.
    @State private var drag: CGSize = .zero

    /// 이만큼 아래로(또는 옆으로) 밀고 놓으면 닫는다.
    private static let dismissDown: CGFloat = 36
    private static let dismissSide: CGFloat = 60

    public var body: some View {
        HStack(spacing: 8) {
            // 다시 불릴 때마다(id가 바뀔 때마다) 아이콘·글자 줄만 새로 올라온다.
            HStack(spacing: 12) {
                ToastStatusIcon(status: state.status)
                Text(state.message)
                    .font(.pretendard.bodyS)
                    .foregroundStyle(Color.component.toast.default.text)
                    .lineHeight(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(state.id)
            .transition(contentTransition)

            if let button = state.button {
                Button(button.title) {
                    onButtonTapped(button.action)
                }
                .buttonStyle(ToastTextButtonStyle())
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.component.toast.strong.background)
                .shadow(color: Color.component.toast.strong.shadow, radius: 14, x: 0, y: 10)
        )
        .animation(Self.contentAnimation, value: state.id)
        .offset(x: drag.width, y: dragOffsetY)
        .opacity(dragOpacity)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { drag = $0.translation }
                .onEnded { value in
                    if value.translation.height > Self.dismissDown
                        || abs(value.translation.width) > Self.dismissSide {
                        onSwipe()
                    } else {
                        // 위로 끌면 1/4만 따라오고(위로는 닫히지 않음), 놓으면 제자리로 돌아온다.
                        withAnimation(.spring(duration: 0.35, bounce: 0.2)) { drag = .zero }
                    }
                }
        )
        .accessibilityElement(children: .combine)
    }

    /// 아래로는 손가락을 그대로, 위로는 1/4만 따라온다(위로는 닫히지 않음을 손끝으로 알림).
    private var dragOffsetY: CGFloat {
        let deltaY: CGFloat = drag.height
        return deltaY > 0 ? deltaY : deltaY * 0.25
    }

    /// 아래로 끌수록 흐려진다(최소 0.3).
    private var dragOpacity: Double {
        let down: CGFloat = max(0, drag.height)
        return Double(max(0.3, 1 - down / 120))
    }

    /// 아이콘·글자가 바뀔 때: 8 아래에서 올라오며 진해지고, 앞 글자는 바로 빠진다.
    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion: reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)),
            removal: AnyTransition.opacity.animation(.easeOut(duration: 0.08))
        )
    }

    /// 웹 ease-smooth-out(cubic-bezier 0.2, 0.8, 0.2, 1) 300ms
    static let contentAnimation: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.3)
}

// MARK: - 화면에 붙이기

public extension View {
    /// 화면 아래에 토스트를 띄운다. 나타남(16 아래·0.96에서 0.5초 스프링으로 떠오름)과
    /// 사라짐(8 내려가며 0.2초에 흐려짐)이 들어 있어 화면에서 따로 animation을 걸지 않는다.
    ///
    /// - Parameters:
    ///   - horizontalPadding: 화면 좌우 여백
    ///   - bottomPadding: 화면 아래 여백. 없으면 `ToastState.bottomPadding`을 쓴다.
    func toast(
        _ state: ToastState?,
        horizontalPadding: CGFloat = 24,
        bottomPadding: CGFloat? = nil,
        onSwipe: @escaping () -> Void,
        onButtonTapped: @escaping (ToastState.Action) -> Void
    ) -> some View {
        overlay(alignment: .bottom) {
            ToastHost(
                state: state,
                horizontalPadding: horizontalPadding,
                bottomPadding: bottomPadding,
                onSwipe: onSwipe,
                onButtonTapped: onButtonTapped
            )
        }
    }
}

private struct ToastHost: View {
    let state: ToastState?
    let horizontalPadding: CGFloat
    let bottomPadding: CGFloat?
    let onSwipe: () -> Void
    let onButtonTapped: (ToastState.Action) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let state {
                ToastView(state: state, onSwipe: onSwipe, onButtonTapped: onButtonTapped)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, bottomPadding ?? state.bottomPadding)
                    .transition(transition)
            }
        }
        // 떠 있는지 여부가 바뀔 때만 상자를 움직인다 — 다시 불릴 때는 상자가 그대로 있다.
        .animation(.spring(duration: 0.5, bounce: 0.2), value: state != nil)
    }

    private var transition: AnyTransition {
        // 동작 줄이기 설정이면 옅게 나타나고 사라지기만 한다.
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: AnyTransition.opacity
                .combined(with: .offset(y: 16))
                .combined(with: .scale(scale: 0.96, anchor: .bottom))
                .animation(.spring(duration: 0.5, bounce: 0.2)),
            removal: AnyTransition.opacity
                .combined(with: .offset(y: 8))
                .animation(.easeIn(duration: 0.2))
        )
    }
}

// MARK: - 부품

/// 면 없는 하늘색 글자 버튼 — 상자 하나에 색 면은 짙은 바탕 하나만 둔다. 누르는 동안만 흰색 20% 면.
private struct ToastTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard.buttonS)
            .foregroundStyle(Color.component.toast.action.text)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? Color.component.toast.action.pressedBg : .clear)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// 상태 아이콘 20 — 색 면 위에 짙은 기호(실패만 흰 기호). 웹 ToastIcon과 같은 그림.
struct ToastStatusIcon: View {
    let status: ToastState.Status

    let colors = Color.component.toast.icon

    var body: some View {
        Canvas { context, size in
            let scale = size.width / 20
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
            func line(_ points: [CGPoint], _ color: Color) {
                var path = Path()
                path.addLines(points)
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: 1.8 * scale, lineCap: .round, lineJoin: .round))
            }
            func dot(_ x: CGFloat, _ y: CGFloat, _ color: Color) {
                let radius = 1.1 * scale
                context.fill(Path(ellipseIn: CGRect(x: x * scale - radius, y: y * scale - radius, width: radius * 2, height: radius * 2)),
                             with: .color(color))
            }
            let disc = Path(ellipseIn: CGRect(x: 1 * scale, y: 1 * scale, width: 18 * scale, height: 18 * scale))

            switch status {
            case .success:
                context.fill(disc, with: .color(colors.success))
                line([p(6, 10.3), p(8.6, 12.8), p(14, 7.6)], colors.mark)
            case .info:
                context.fill(disc, with: .color(colors.info))
                line([p(10, 9), p(10, 14)], colors.mark)
                dot(10, 6.2, colors.mark)
            case .warning:
                // 모서리 1.6을 둥글린 세모
                var triangle = Path()
                let apex = p(10, 0.15), right = p(19.97, 17.6), left = p(0.03, 17.6)
                triangle.move(to: p(10, 17.6))
                triangle.addArc(tangent1End: right, tangent2End: apex, radius: 1.6 * scale)
                triangle.addArc(tangent1End: apex, tangent2End: left, radius: 1.6 * scale)
                triangle.addArc(tangent1End: left, tangent2End: right, radius: 1.6 * scale)
                triangle.closeSubpath()
                context.fill(triangle, with: .color(colors.warning))
                line([p(10, 7.2), p(10, 11.6)], colors.mark)
                dot(10, 14.3, colors.mark)
            case .error:
                context.fill(disc, with: .color(colors.error))
                line([p(7.2, 7.2), p(12.8, 12.8)], colors.markOnError)
                line([p(12.8, 7.2), p(7.2, 12.8)], colors.markOnError)
            }
        }
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }
}

#Preview("토스트 상태") {
    VStack(spacing: 12) {
        ToastView(state: .init(message: "포지션을 저장했어요", status: .success), onSwipe: {}, onButtonTapped: { _ in })
        ToastView(state: .init(message: "시간이 지나 가입이 중단됐어요. 다시 로그인해주세요.", status: .info), onSwipe: {}, onButtonTapped: { _ in })
        ToastView(state: .init(message: "사진은 최대 3장까지 올릴 수 있어요", status: .warning), onSwipe: {}, onButtonTapped: { _ in })
        ToastView(state: .init(message: "알림 설정을 불러오지 못했어요.", status: .error,
                               button: .init(title: "다시 시도", action: .done)), onSwipe: {}, onButtonTapped: { _ in })
    }
    .padding(24)
}
