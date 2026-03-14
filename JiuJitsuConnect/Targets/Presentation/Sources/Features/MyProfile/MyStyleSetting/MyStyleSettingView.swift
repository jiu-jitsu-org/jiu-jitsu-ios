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
                        Gradient.Stop(color: Color(hex: "#EDEFF0").opacity(0), location: 0.0),
                        Gradient.Stop(color: Color(hex: "#EDEFF0").opacity(1.0), location: 1.0)
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
        .background(Color.component.background.default)
        .navigationTitle(store.settingType.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
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
        ScrollView {
            VStack(spacing: 0) {
                // 탭 (특기/최애)
                HStack {
                    Spacer()
                    tabView
                    Spacer()
                }
                .padding(.top, 26)
                
                // 메인 카드
                styleCardsView
                    .padding(.top, 26)
                
                // 선택 가능한 스타일 미리보기 (스크롤뷰 내부)
                selectedStylesPreview
                    .padding(.top, 29)
            }
        }
        .background(Color.component.background.default)
        .scrollEdgeEffectStyle(.soft, for: .top)    // 상단 부드러운 페이드
        .scrollEdgeEffectStyle(.soft, for: .bottom) // 하단 부드러운 페이드
    }
    
    private var styleCardsView: some View {
        // 현재 탭에서 선택된 스타일
        let currentStyle = store.currentSelectedStyle
        
        return HStack {
            Spacer()
            
            if let style = currentStyle {
                // 선택된 스타일 카드 (플립 가능)
                FlippableStyleCard(style: style, settingType: store.settingType)
            } else {
                // "없음"이 선택된 상태 - EmptySelectionCard 표시
                EmptySelectionCard(
                    onTap: {
                        // 탭 동작 없음 (이미 선택된 상태)
                    }
                )
            }
            
            Spacer()
        }
        .frame(height: 394)
    }
    
    private var completeButton: some View {
        VStack(spacing: 0) {
            CTAButton(
                title: completeButtonTitle,
                type: .blue,
                style: .rounded,
                height: 51,
                action: {
                    store.send(.view(.completeButtonTapped))
                }
            )
            .disabled(!store.canComplete)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private var completeButtonTitle: String {
        if store.selectedBestStyle == nil {
            return "특기 설정 완료"
        } else if store.selectedTab == .best {
            return "특기 설정 완료"
        } else {
            return "최애 설정 완료"
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
    }
    
    private var resetButton: some View {
        Button {
            store.send(.view(.resetButtonTapped))
        } label: {
            Text("나중에 하기")
                .font(Font.pretendard.buttonS)
                .foregroundStyle(Color.component.button.text.defaultText)
                .padding(.horizontal, 4)
                .padding(.vertical, 9)
                .frame(height: 32)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab View
    
    private var tabView: some View {
        SegmentControl(
            leftItem: SegmentItem(
                title: "특기",
                subtitle: subtitleForBest
            ),
            rightItem: SegmentItem(
                title: "최애",
                subtitle: subtitleForFavorite
            ),
            selectedSide: store.selectedTab == .best ? .left : .right
        ) { newSide in
            let newTab: MyStyleSettingFeature.SelectionTab = newSide == .left ? .best : .favorite
            store.send(.view(.tabSelected(newTab)))
        }
    }
    
    /// 특기 탭의 subtitle
    private var subtitleForBest: String {
        if let bestStyle = store.selectedBestStyle {
            return bestStyle.tabTitle
        } else {
            return "입력해주세요"
        }
    }
    
    /// 최애 탭의 subtitle
    private var subtitleForFavorite: String {
        if let favoriteStyle = store.selectedFavoriteStyle {
            return favoriteStyle.tabTitle
        } else {
            return "입력해주세요"
        }
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
                            NoneStyleCard(isSelected: store.currentSelectedStyle == nil)
                                .onTapGesture {
                                    // 현재 탭의 선택을 해제
                                    if let currentStyle = store.currentSelectedStyle {
                                        store.send(.view(.styleCardTapped(currentStyle)))
                                    }
                                }
                            
                            // 나머지 스타일 카드들
                            ForEach(store.availableStyles, id: \.id) { style in
                                SmallStyleCard(
                                    style: style,
                                    label: style.shortTitle,
                                    isSelected: isStyleSelected(style)
                                )
                                .onTapGesture {
                                    store.send(.view(.styleCardTapped(style)))
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
                        NoneStyleCard(isSelected: store.currentSelectedStyle == nil)
                            .onTapGesture {
                                // 현재 탭의 선택을 해제
                                if let currentStyle = store.currentSelectedStyle {
                                    store.send(.view(.styleCardTapped(currentStyle)))
                                }
                            }
                        
                        // 나머지 스타일 카드들
                        ForEach(store.availableStyles, id: \.id) { style in
                            SmallStyleCard(
                                style: style,
                                label: style.shortTitle,
                                isSelected: isStyleSelected(style)
                            )
                            .onTapGesture {
                                store.send(.view(.styleCardTapped(style)))
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
        // 현재 탭에서 선택된 스타일과 비교
        return store.currentSelectedStyle?.id == style.id
    }
}

// MARK: - Style Card

private struct StyleCard: View {
    let style: any StyleSelectable
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .center) {
            // 배경 이미지 - 카드 크기에 딱 맞게 (비율 무시하고 꽉 채움)
            style.backgroundImage.swiftUIImage
                .resizable()
                .frame(width: 262, height: 394)
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // 아이콘
                style.iconImage.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 93, height: 93)
                    .padding(.bottom, 54)
                
                // 풀 타이틀
                Text(style.fullTitle)
                    .font(.cookieRun.custom(weight: .black, size: 40))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: 54)
                    .padding(.bottom, 20)
                
                // 카드 설명
                Text(style.cardDescription)
                    .font(.pretendard.custom(weight: .medium, size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(height: 72)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 32)
            }
        }
        .frame(width: 262, height: 394)
        .cornerRadius(40)
//        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Style Card Back

private struct StyleCardBack: View {
    let style: any StyleSelectable
    let settingType: MyStyleSettingType

    var body: some View {
        ZStack {
            // 배경 색상 - 고정된 회색
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.primitive.coolGray.cg75)

            VStack(alignment: .center, spacing: 7) {
                // 타이틀 - 화면 타입 표시 (포지션/서브미션/기술)
                Text(settingType.navigationTitle)
                    .font(.pretendard.bodyM)
                    .foregroundColor(.primitive.coolGray.cg400)

                // 캡션 - 스타일 타이틀
                Text(style.fullTitle)
                    .font(.pretendard.display1)
                    .lineSpacing(5)
                    .foregroundColor(.primitive.coolGray.cg600)
            }
        }
        .frame(width: 262, height: 394)
    }
}

// MARK: - Flippable Style Card

private struct FlippableStyleCard: View {
    let style: any StyleSelectable
    let settingType: MyStyleSettingType

    @State private var dragAngle: Double = 0
    @State private var cumulativeRotation: Double = 0  // 누적 회전각

    // 현재 총 회전각 기준으로 앞/뒷면 판단
    private var showBack: Bool {
        let normalized = dragAngle.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return (positive > 90 && positive < 270)
    }
    
    // 회전 각도 기반으로 섀도우 강도 계산 (0.0 ~ 1.0)
    private var shadowIntensity: Double {
        let normalized = abs(dragAngle).truncatingRemainder(dividingBy: 180)
        let progress = normalized / 180  // 0 = 정면, 0.5 = 옆면, 1.0 = 뒷면
        // 정면/뒷면: 1.0, 옆면(90도): 0.0
        return abs(cos(progress * .pi))
    }
    
    // 회전 시 카드가 옆으로 기울어지면 X 오프셋도 살짝 변화
    private var shadowOffsetX: Double {
        sin(dragAngle * .pi / 180) * 6  // 회전 방향으로 그림자 이동
    }

    var body: some View {
        ZStack {
            // 뒷면 (처음부터 180도 뒤집어 대기)
            StyleCardBack(style: style, settingType: settingType)
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(showBack ? 1 : 0)

            // 앞면
            StyleCard(style: style, isSelected: true)
                .opacity(showBack ? 0 : 1)
        }
        .rotation3DEffect(
            .degrees(dragAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        // Shadow 1 - 기본 섀도우 (Blur: 12, Color: #000000 20%)
        .shadow(
            color: Color.black.opacity(0.20 * shadowIntensity),
            radius: 6,   // Blur 12 → radius 6
            x: shadowOffsetX,
            y: 2
        )
        // Shadow 2 - 깊이감 섀도우 (Blur: 24, Spread: 4, Color: #000000 25%)
        .shadow(
            color: Color.black.opacity(0.25 * shadowIntensity),
            radius: 14,  // Blur 24 → radius 12, spread 4 보정 +2
            x: shadowOffsetX,
            y: 2
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 누적 회전각에 드래그 이동량을 더함 (양방향 지원)
                    dragAngle = cumulativeRotation + value.translation.width * 0.5
                }
                .onEnded { value in
                    let dragDistance = value.translation.width
                    // 속도 기반으로 넘길지 복귀할지 판단
                    let velocity = value.predictedEndTranslation.width - value.translation.width
                    let shouldFlip = abs(dragDistance) > 60 || abs(velocity) > 30

                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        if shouldFlip {
                            // 드래그 방향에 따라 ±180도 회전
                            if dragDistance < 0 {
                                cumulativeRotation -= 180  // 왼쪽으로 드래그 → 왼쪽 회전
                            } else {
                                cumulativeRotation += 180  // 오른쪽으로 드래그 → 오른쪽 회전
                            }
                            dragAngle = cumulativeRotation
                        } else {
                            // 복귀
                            dragAngle = cumulativeRotation
                        }
                    }
                }
        )
    }
}

// MARK: - Card Components
// ℹ️ 다음 컴포넌트들이 별도 파일로 분리됨:
// - SmallStyleCard.swift
// - NoneStyleCard.swift
// - EmptySelectionCard.swift

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
