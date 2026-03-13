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
        HStack(spacing: 0) {
            ForEach(MyStyleSettingFeature.SelectionTab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.displayName,
                    subtitle: subtitle(for: tab),
                    isSelected: store.selectedTab == tab
                ) {
                    store.send(.view(.tabSelected(tab)))
                }
            }
        }
        .frame(width: 262, height: 67)
        .background(Color.component.segment.container.bg)
        .cornerRadius(28)
    }
    
    /// 각 탭의 subtitle을 선택된 스타일에 따라 동적으로 반환
    private func subtitle(for tab: MyStyleSettingFeature.SelectionTab) -> String {
        switch tab {
        case .best:
            return store.selectedBestStyle?.tabTitle ?? defaultSubtitle(for: .best)
        case .favorite:
            return store.selectedFavoriteStyle?.tabTitle ?? defaultSubtitle(for: .favorite)
        }
    }
    
    /// 선택되지 않았을 때 기본 subtitle
    private func defaultSubtitle(for tab: MyStyleSettingFeature.SelectionTab) -> String {
        switch store.settingType {
        case .position:
            return tab == .best ? "탑포지션" : "가드포지션"
        case .submission:
            return tab == .best ? "암바" : "레그락"
        case .technique:
            return tab == .best ? "테이크다운" : "이스케이프"
        }
    }
    
    // MARK: - Selected Styles Preview
    
    private var selectedStylesPreview: some View {
        // 컨테이너: 120 높이 고정, 좌우 여백 없음
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if needsScrolling(containerWidth: geometry.size.width) {
                    // 스크롤이 필요한 경우: ScrollView 사용
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CardMetrics.Spacing.horizontal) {
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
                        .frame(height: CardMetrics.Size.selectedHeight)
                        .padding(.horizontal, CardMetrics.Spacing.containerPadding)
                        .padding(.vertical, 16)
                    }
                } else {
                    // 스크롤이 필요 없는 경우: 가운데 정렬된 HStack
                    HStack(spacing: CardMetrics.Spacing.horizontal) {
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
                    .frame(height: CardMetrics.Size.selectedHeight)
                    .padding(.vertical, 16)
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

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.pretendard.custom(weight: .semiBold, size: 18))
                    .foregroundColor(isSelected ? Color.component.segment.selected.titleText : Color.component.segment.unselected.titleText)
                
                Text(subtitle)
                    .font(Font.pretendard.labelM)
                    .foregroundColor(isSelected ? Color.component.segment.selected.subText : Color.component.segment.unselected.subText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 59)
            .background(isSelected ? Color.component.segment.selected.bg : Color.component.segment.unselected.bg)
            .cornerRadius(24)
            .padding([.top, .bottom, .leading], 4)
        }
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

// MARK: - Small Style Card (Preview)

private struct SmallStyleCard: View {
    let style: any StyleSelectable
    let label: String
    let isSelected: Bool
    
    // 선택 여부에 따른 사이즈
    private var cardWidth: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Size.selectedWidth
                   : MyStyleSettingView.CardMetrics.Size.unselectedWidth
    }
    
    private var cardHeight: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Size.selectedHeight
                   : MyStyleSettingView.CardMetrics.Size.unselectedHeight
    }
    
    private var cornerRadius: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.CornerRadius.selected
                   : MyStyleSettingView.CardMetrics.CornerRadius.unselected
    }
    
    private var fontSize: CGFloat {
        MyStyleSettingView.CardMetrics.Font.size
    }
    
    private var topPadding: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Padding.selectedTop
                   : MyStyleSettingView.CardMetrics.Padding.unselectedTop
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 배경 색상 - style마다 다른 색상 사용
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: style.smallCardColorHex))
            
            // 짧은 타이틀을 상단에 배치 - 중앙 정렬
            Text(style.shortTitle)
                .font(.cookieRun.custom(weight: .black, size: fontSize))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, topPadding)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: topPadding)
        }
        .frame(width: cardWidth, height: cardHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - None Style Card (첫 번째 카드)

private struct NoneStyleCard: View {
    let isSelected: Bool
    
    // 선택 여부에 따른 사이즈
    private var cardWidth: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Size.selectedWidth
                   : MyStyleSettingView.CardMetrics.Size.unselectedWidth
    }
    
    private var cardHeight: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Size.selectedHeight
                   : MyStyleSettingView.CardMetrics.Size.unselectedHeight
    }
    
    private var cornerRadius: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.CornerRadius.selected
                   : MyStyleSettingView.CardMetrics.CornerRadius.unselected
    }
    
    private var fontSize: CGFloat {
        MyStyleSettingView.CardMetrics.Font.size
    }
    
    private var topPadding: CGFloat {
        isSelected ? MyStyleSettingView.CardMetrics.Padding.selectedTop
                   : MyStyleSettingView.CardMetrics.Padding.unselectedTop
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 배경 색상 - 고정된 회색
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: "#4F535B"))
            
            // "없음" 타이틀을 상단에 배치 - 중앙 정렬
            Text("없음")
                .font(.cookieRun.custom(weight: .black, size: fontSize))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, topPadding)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: topPadding)
        }
        .frame(width: cardWidth, height: cardHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Empty Selection Card (Default State)

private struct EmptySelectionCard: View {
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // 배경 - 점선 테두리와 어두운 배경
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.primitive.coolGray.cg900)
            
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 8])
                )
                .foregroundColor(Color.primitive.coolGray.cg200)
            
            // + 아이콘을 중앙에 배치
            VStack(spacing: 0) {
                // + 아이콘 (배경 원 없이)
                Text("+")
                    .font(Font.cookieRun.custom(weight: .black, size: 80))
                    .foregroundColor(Color.primitive.coolGray.cg100)
                
                // "선택하기" 텍스트
                Text("선택하기")
                    .font(Font.cookieRun.custom(weight: .black, size: 20))
                    .foregroundColor(Color.primitive.coolGray.cg100)
                    .frame(height: 27)
                    .padding(.top, -5)
            }
            .offset(y: -13.5)
        }
        .frame(width: 262, height: 394)
        .cornerRadius(40)
    }
}

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
