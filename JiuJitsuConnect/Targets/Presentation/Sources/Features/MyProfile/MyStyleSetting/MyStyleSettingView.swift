//
//  MyStyleSettingView.swift
//  Presentation
//
//  Created by suni on 2/22/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import CoreKit
import Domain

public struct MyStyleSettingView: View {
    @Bindable var store: StoreOf<MyStyleSettingFeature>

    /// 카드가 앞면으로 돌아 조명이 켜진 단계. 단계(포지션 · 기술 · 서브미션)마다 처음 한 번만 돈다.
    ///
    /// 가입 흐름은 화면을 그대로 둔 채 단계만 바꾼다. 켜짐 여부(Bool)를 단계가 바뀐 뒤 끄면
    /// 새 카드가 아직 켜진 값으로 만들어져 돌지 않으므로, 어느 단계에서 켜졌는지를 기억한다.
    @State private var revealedType: MyStyleSettingType?

    private var isRevealed: Bool { revealedType == store.settingType }

    /// 아래 줄에서 바꿀 때 새 카드가 들어오는 쪽
    @State private var swapDirection = CardSwapDirection()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 동작 줄이기를 켰으면 조명이 바로 켜진다
    private var lightAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: StageMetrics.lightDuration)
    }

    public init(store: StoreOf<MyStyleSettingFeature>) {
        self.store = store
    }
    
    // MARK: - Layout Constants
    
    fileprivate enum CardMetrics {
        enum Size {
            static let selectedWidth: CGFloat = 73.53
            static let selectedHeight: CGFloat = 88
            static let unselectedWidth: CGFloat = 55
            static let unselectedHeight: CGFloat = 65
        }
        
        enum CornerRadius {
            static let selected: CGFloat = 19.29
            static let unselected: CGFloat = 14.4
        }
        
        enum Spacing {
            static let horizontal: CGFloat = 8
            static let containerPadding: CGFloat = 36
        }
        
        enum Font {
            static let size: CGFloat = 16  // 선택/비선택 모두 동일
        }
        
        enum Padding {
            static let selectedTop: CGFloat = 20
            static let unselectedTop: CGFloat = 14.7
        }

        /// 고른 카드만 조명을 받게 나머지 카드는 어둡게 가라앉힌다
        static let dimmedOpacity: Double = 0.3
    }

    private enum StageMetrics {
        static let background = Color(hex: "#1E1E1E")
        static let dimmedText = Color.white.opacity(0.6)
        static let cardSize = CGSize(width: 262, height: 394)
        static let lightDuration: Double = 0.7
        /// 조명이 켜지기 전 카드는 어둠 속에 있다
        static let unlitBrightness: Double = -0.35
        static let swapAnimation: Animation = .spring(response: 0.48, dampingFraction: 0.72)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                mainScrollView
                
                // 완료 버튼 영역
                Spacer()
                    .frame(height: 59) // 버튼 높이만큼 공간 확보
            }
            
            // 그라데이션 배경 (화면 하단에서 위로)
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: StageMetrics.background.opacity(0), location: 0.0),
                        Gradient.Stop(color: StageMetrics.background, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 73)
                .frame(maxWidth: .infinity)
                
                Spacer()
                    .frame(height: 38)
            }
            .allowsHitTesting(false)
            
            // 완료 버튼
            completeButton
        }
        .background(StageMetrics.background)
        // 아래 '완료' 버튼을 가리지 않도록 버튼 위에 띄운다.
        .toast(
            store.toast,
            bottomPadding: 120,
            onSwipe: { store.send(.view(.toastSwiped)) },
            onButtonTapped: { _ in store.send(.view(.toastSwiped)) }
        )
        // 특기/최애 탭이 없어져(#118) 무엇을 고르는 화면인지 제목에서 알린다
        .navigationTitle("최애 \(store.settingType.title)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        // 어두운 바탕이라 상태 바 글자를 밝게 한다
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("최애 \(store.settingType.title)")
                    .font(.pretendard.custom(weight: .semiBold, size: 17))
                    .foregroundStyle(StageMetrics.dimmedText)
            }

            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
            .sharedBackgroundVisibility(.hidden)
            
            ToolbarItem(placement: .topBarTrailing) {
                resetButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
    
    // MARK: - Main Content Views
    
    private var mainScrollView: some View {
        GeometryReader { proxy in
            ScrollView {
                // 특기/최애 탭이 빠져(#118) 남는 높이는 카드 위아래로 나눠, 고르는 줄은
                // 탭이 있던 때처럼 완료 버튼 바로 위에 붙인다.
                VStack(spacing: 0) {
                    Spacer(minLength: 26)

                    // 메인 카드
                    styleCardsView

                    Spacer(minLength: 29)

                    // 선택 가능한 스타일 미리보기 (스크롤뷰 내부)
                    selectedStylesPreview
                }
                .frame(minHeight: proxy.size.height)
            }
        }
        // 조명 윗부분이 스크롤 경계에서 잘리지 않게 한다
        .scrollClipDisabled()
        .scrollEdgeEffectStyle(.soft, for: .top)    // 상단 부드러운 페이드
        .scrollEdgeEffectStyle(.soft, for: .bottom) // 하단 부드러운 페이드
    }
    
    private var styleCardsView: some View {
        let currentStyle = store.selectedFavoriteStyle

        // 바꿀 때 이전 카드와 새 카드가 잠깐 겹쳐 지나가도록 ZStack에 둔다
        return ZStack {
            if let style = currentStyle {
                // 선택된 스타일 카드 (플립 가능)
                FlippableStyleCard(
                    category: store.settingType.title,
                    style: style,
                    beltRank: store.beltRank,
                    playsIntro: !isRevealed,
                    onRevealed: {
                        withAnimation(lightAnimation) { revealedType = store.settingType }
                    }
                )
                .brightness(isRevealed ? 0 : StageMetrics.unlitBrightness)
                // 다른 카드를 고르거나 다음 단계(기술 · 서브미션)로 넘어가면 새 카드로 바뀐다
                .id("\(store.settingType.title)-\(style.id)")
                .transition(cardSwapTransition)
            } else {
                // "없음"이 선택된 상태 - EmptySelectionCard 표시
                EmptySelectionCard(
                    onTap: {
                        // 탭 동작 없음 (이미 선택된 상태)
                    }
                )
                .transition(cardSwapTransition)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: StageMetrics.cardSize.height)
        .background {
            StageLight(cardSize: StageMetrics.cardSize, cornerRadius: StyleCardMetrics.cornerRadius)
                .opacity(isRevealed && currentStyle != nil ? 1 : 0)
                .animation(lightAnimation, value: currentStyle == nil)
        }
    }

    // MARK: - Card Swap

    /// 새 카드는 고른 쪽에서 밀려 들어오고, 이전 카드는 반대쪽으로 기울며 빠진다(#495)
    private var cardSwapTransition: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: CardSwapEffect(phase: .incoming, direction: swapDirection),
                identity: CardSwapEffect(phase: .settled, direction: swapDirection)
            ),
            removal: .modifier(
                active: CardSwapEffect(phase: .outgoing, direction: swapDirection),
                identity: CardSwapEffect(phase: .settled, direction: swapDirection)
            )
        )
    }

    /// 아래 줄에서 카드를 눌렀을 때
    private func styleTapped(_ style: any StyleSelectable) {
        // 고른 카드를 다시 누르면 선택이 풀려 맨 앞 '없음'으로 간다
        let current = store.selectedFavoriteStyle
        let next: (any StyleSelectable)? = current?.id == style.id ? nil : style
        guard !reduceMotion else {
            store.send(.view(.styleCardTapped(style)))
            return
        }
        swapDirection.value = lineIndex(of: next) >= lineIndex(of: current) ? 1 : -1
        store.send(.view(.styleCardTapped(style)), animation: StageMetrics.swapAnimation)
    }

    /// 아래 줄에서의 자리. '없음'이 맨 앞(-1)이다.
    private func lineIndex(of style: (any StyleSelectable)?) -> Int {
        guard let style else { return -1 }
        return store.availableStyles.firstIndex { $0.id == style.id } ?? -1
    }

    private var completeButton: some View {
        VStack(spacing: 0) {
            CTAButton(
                title: "\(store.settingType.title) 설정 완료",
                type: .blue,
                style: .rounded,
                height: 51,
                action: {
                    store.send(.view(.completeButtonTapped))
                }
            )
            .disabled(store.isSaving)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private var backButton: some View {
        Button(action: { store.send(.view(.backButtonTapped)) }) {
            ZStack {
                // 라운드 배경
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primitive.coolGray.cg50)
                
                Assets.Common.Icon.arrowLeft.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.primitive.coolGray.cg700)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로 가기")
        .disabled(store.isSaving)
    }
    
    private var resetButton: some View {
        Button {
            store.send(.view(.resetButtonTapped))
        } label: {
            // 툴바가 정해 주는 폭이 글자보다 좁아 '나중에 ...'로 잘렸다(#471). 글자 폭만큼은 차지하게 한다
            Text("나중에 하기")
                .font(Font.pretendard.buttonS)
                .foregroundStyle(StageMetrics.dimmedText)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 4)
                .padding(.vertical, 9)
                .frame(height: 32)
        }
        .buttonStyle(.plain)
        .disabled(store.isSaving)
    }
    
    // MARK: - Selected Styles Preview
    
    private var selectedStylesPreview: some View {
        // 컨테이너: 120 높이 고정, 좌우 여백 없음
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                if needsScrolling(containerWidth: geometry.size.width) {
                    // 스크롤이 필요한 경우: ScrollView 사용
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: CardMetrics.Spacing.horizontal) {
                            // "없음" 카드 (첫 번째)
                            NoneStyleCard(isSelected: store.selectedFavoriteStyle == nil)
                                .opacity(store.selectedFavoriteStyle == nil ? 1 : CardMetrics.dimmedOpacity)
                                .onTapGesture {
                                    // 고른 것을 해제
                                    if let currentStyle = store.selectedFavoriteStyle {
                                        styleTapped(currentStyle)
                                    }
                                }
                            
                            // 나머지 스타일 카드들
                            ForEach(store.availableStyles, id: \.id) { style in
                                SmallStyleCard(
                                    style: style,
                                    label: style.shortTitle,
                                    isSelected: isStyleSelected(style)
                                )
                                .opacity(isStyleSelected(style) ? 1 : CardMetrics.dimmedOpacity)
                                .onTapGesture {
                                    styleTapped(style)
                                }
                            }
                        }
                        .padding(.horizontal, CardMetrics.Spacing.containerPadding)
                        .padding(.bottom, 16)
                    }
                } else {
                    // 스크롤이 필요 없는 경우: 가운데 정렬된 HStack
                    HStack(alignment: .bottom, spacing: CardMetrics.Spacing.horizontal) {
                        // "없음" 카드 (첫 번째)
                        NoneStyleCard(isSelected: store.selectedFavoriteStyle == nil)
                            .opacity(store.selectedFavoriteStyle == nil ? 1 : CardMetrics.dimmedOpacity)
                            .onTapGesture {
                                // 고른 것을 해제
                                if let currentStyle = store.selectedFavoriteStyle {
                                    styleTapped(currentStyle)
                                }
                            }
                        
                        // 나머지 스타일 카드들
                        ForEach(store.availableStyles, id: \.id) { style in
                            SmallStyleCard(
                                style: style,
                                label: style.shortTitle,
                                isSelected: isStyleSelected(style)
                            )
                            .opacity(isStyleSelected(style) ? 1 : CardMetrics.dimmedOpacity)
                            .onTapGesture {
                                styleTapped(style)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity) // 전체 너비 사용
                }
            }
            .frame(height: 120)  // 컨테이너 높이 120 고정
            .frame(maxWidth: .infinity)  // 컨테이너 좌우 여백 없음
        }
        .frame(height: 120)  // GeometryReader에 높이 제약 설정
    }
    
    /// 스크롤이 필요한지 계산
    private func needsScrolling(containerWidth: CGFloat) -> Bool {
        // "없음" 카드 + 나머지 스타일 카드들
        let totalCardCount = store.availableStyles.count + 1
        
        // 선택된 카드 1개 + 선택 안된 카드 (totalCardCount - 1)개
        let totalCardsWidth = CardMetrics.Size.selectedWidth
            + (CardMetrics.Size.unselectedWidth * CGFloat(totalCardCount - 1))
        let totalSpacingWidth = CGFloat(max(0, totalCardCount - 1)) * CardMetrics.Spacing.horizontal
        let horizontalPadding = CardMetrics.Spacing.containerPadding * 2
        let totalWidth = totalCardsWidth + totalSpacingWidth + horizontalPadding
        
        return totalWidth > containerWidth
    }
    
    private func isStyleSelected(_ style: any StyleSelectable) -> Bool {
        store.selectedFavoriteStyle?.id == style.id
    }
}

// MARK: - CardSwapEffect

/// 카드를 바꿀 때 새 카드가 들어오는 쪽 — 1이면 오른쪽에서, -1이면 왼쪽에서.
///
/// 빠지는 카드의 전환 효과는 마지막으로 그려질 때 만들어진다. 방향을 값으로 넘기면 고르기 직전의
/// 방향으로 나가므로, 참조로 넘겨 빠지기 시작하는 순간의 방향을 읽게 한다.
@Observable
private final class CardSwapDirection {
    var value: CGFloat = 1
}

/// 카드를 바꿀 때 옆으로 밀려나는 정도. 제자리면 0, 들어오기 전 · 빠진 뒤면 옆으로 빠져 안 보인다.
private struct CardSwapEffect: ViewModifier {
    enum Phase { case incoming, settled, outgoing }

    let phase: Phase
    let direction: CardSwapDirection

    private var position: CGFloat {
        switch phase {
        case .incoming: return direction.value
        case .settled: return 0
        case .outgoing: return -direction.value
        }
    }

    /// 카드 폭(262)의 약 70%
    private static let distance: CGFloat = 180
    private static let tilt: Double = 10
    private static let shrink: CGFloat = 0.12

    func body(content: Content) -> some View {
        content
            .offset(x: position * Self.distance)
            .rotationEffect(.degrees(position * Self.tilt))
            .scaleEffect(1 - abs(position) * Self.shrink)
            .opacity(1 - abs(position))
    }
}

// MARK: - Card Components
// ℹ️ 모든 카드 컴포넌트들이 별도 파일로 분리됨:
// - FlippableStyleCard.swift (3D 회전 카드)
// - StyleCard.swift (카드 앞면)
// - StyleCardBack.swift (카드 뒷면)
// - SmallStyleCard.swift (미리보기 작은 카드)
// - NoneStyleCard.swift ("없음" 카드)
// - EmptySelectionCard.swift (초기 선택 카드)

// MARK: - Preview

#Preview {
    NavigationStack {
        MyStyleSettingView(
            store: Store(
                initialState: MyStyleSettingFeature.State(settingType: .position)
            ) {
                MyStyleSettingFeature()
            }
        )
    }
}
