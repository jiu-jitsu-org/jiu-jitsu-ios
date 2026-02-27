//
//  MyStyleSettingView.swift
//  Presentation
//
//  Created by suni on 2/22/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct MyStyleSettingView: View {
    @Bindable var store: StoreOf<MyStyleSettingFeature>
    
    public init(store: StoreOf<MyStyleSettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            mainScrollView
            
            // 선택된 스타일 미리보기 (항상 표시)
            selectedStylesPreview
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // 완료 버튼
            completeButton
        }
        .background(Color.component.background.default)
        .navigationTitle("포지션 설정")
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
            // 탭 (특기/최애)
            tabView
                .padding(.top, 26)
                .padding(.horizontal, 50)
            
            // 메인 카드
            styleCardsView
        }
        .background(Color.component.background.default)
        .scrollEdgeEffectStyle(.soft, for: .top)    // 상단 부드러운 페이드
        .scrollEdgeEffectStyle(.hard, for: .bottom) // 하단 선명한 경계
    }
    
    private var styleCardsView: some View {
        let currentStyle: PositionStyle?
        
        switch store.selectedTab {
        case .best:
            currentStyle = store.selectedBestPosition
        case .favorite:
            currentStyle = store.selectedFavoritePosition
        }
        
        return VStack(spacing: 0) {
            if let style = currentStyle {
                // 선택된 스타일 카드
                PositionStyleCard(
                    style: style,
                    isSelected: true
                )
            } else {
                // 선택 전 기본 카드
                EmptySelectionCard(
                    onTap: {
                        // 첫 번째 스타일을 선택하도록 유도하거나 그냥 비워둘 수 있음
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var completeButton: some View {
        Button {
            store.send(.view(.completeButtonTapped))
        } label: {
            completeButtonLabel
        }
        .disabled(!store.canComplete)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .padding(.top, 16)
    }
    
    private var completeButtonLabel: some View {
        let buttonText: String
        if store.selectedBestPosition == nil {
            buttonText = "특기 선정 완료"
        } else if store.selectedTab == .best {
            buttonText = "특기 선정 완료"
        } else {
            buttonText = "최애 선정 완료"
        }
        
        return Text(buttonText)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(store.canComplete ? Color.blue : Color.gray)
            .cornerRadius(12)
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
        .frame(height: 67)
        .background(Color.component.segment.container.bg)
        .cornerRadius(28)
    }
    
    /// 각 탭의 subtitle을 선택된 포지션에 따라 동적으로 반환
    private func subtitle(for tab: MyStyleSettingFeature.SelectionTab) -> String {
        switch tab {
        case .best:
            return store.selectedBestPosition?.displayName ?? "탑포지션"
        case .favorite:
            return store.selectedFavoritePosition?.displayName ?? "가드포지션"
        }
    }
    
    // MARK: - Selected Styles Preview
    
    private var selectedStylesPreview: some View {
        // 선택 가능한 스타일들을 가로 스크롤로 표시
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.availableStyles) { style in
                    SmallStyleCard(
                        style: style,
                        label: style.displayName,
                        isSelected: isStyleSelected(style)
                    )
                    .onTapGesture {
                        store.send(.view(.styleCardTapped(style)))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func isStyleSelected(_ style: PositionStyle) -> Bool {
        switch store.selectedTab {
        case .best:
            return store.selectedBestPosition == style
        case .favorite:
            return store.selectedFavoritePosition == style
        }
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

// MARK: - Position Style Card

private struct PositionStyleCard: View {
    let style: PositionStyle
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: style.backgroundColors.top),
                    Color(hex: style.backgroundColors.bottom)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    // 실제로는 에셋의 아이콘을 사용해야 합니다
                    Image(systemName: "figure.martial.arts")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // 스타일 이름
                Text(style.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // 설명
                Text(style.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 40)
            
            // 선택 표시
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white, lineWidth: 3)
            }
        }
        .frame(height: 320)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Small Style Card (Preview)

private struct SmallStyleCard: View {
    let style: PositionStyle
    let label: String
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: style.backgroundColors.top),
                    Color(hex: style.backgroundColors.bottom)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 4) {
                // 아이콘 또는 텍스트
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // 선택 표시
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white, lineWidth: 2)
            }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(12)
    }
}

// MARK: - Empty Selection Card (Default State)

private struct EmptySelectionCard: View {
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // 배경 - 점선 테두리와 어두운 배경
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "2C2C2E"))
            
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .foregroundColor(Color.white.opacity(0.3))
            
            VStack(spacing: 20) {
                // + 아이콘
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white)
                }
                
                // "선택하기" 텍스트
                Text("선택하기")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 40)
        }
        .frame(height: 320)
    }
}

// MARK: - Color Extension

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MyStyleSettingView(
            store: Store(
                initialState: MyStyleSettingFeature.State()
            ) {
                MyStyleSettingFeature()
            }
        )
    }
}
