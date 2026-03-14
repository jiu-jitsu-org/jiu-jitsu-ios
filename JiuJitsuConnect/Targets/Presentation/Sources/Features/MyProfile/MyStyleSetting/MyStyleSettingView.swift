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
