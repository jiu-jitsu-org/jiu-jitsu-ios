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
        // 특기/최애 탭이 없어져(#118) 무엇을 고르는 화면인지 제목에서 알린다
        .navigationTitle("최애 \(store.settingType.title)")
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
        .background(Color.component.background.default)
        .scrollEdgeEffectStyle(.soft, for: .top)    // 상단 부드러운 페이드
        .scrollEdgeEffectStyle(.soft, for: .bottom) // 하단 부드러운 페이드
    }
    
    private var styleCardsView: some View {
        let currentStyle = store.selectedFavoriteStyle
        
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
                title: "\(store.settingType.title) 설정 완료",
                type: .blue,
                style: .rounded,
                height: 51,
                action: {
                    store.send(.view(.completeButtonTapped))
                }
            )
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
                                .onTapGesture {
                                    // 고른 것을 해제
                                    if let currentStyle = store.selectedFavoriteStyle {
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
                        NoneStyleCard(isSelected: store.selectedFavoriteStyle == nil)
                            .onTapGesture {
                                // 고른 것을 해제
                                if let currentStyle = store.selectedFavoriteStyle {
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
        store.selectedFavoriteStyle?.id == style.id
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
