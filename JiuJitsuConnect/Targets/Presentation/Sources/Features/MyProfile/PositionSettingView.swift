//
//  PositionSettingView.swift
//  Presentation
//
//  Created by suni on 2/22/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct PositionSettingView: View {
    @Bindable var store: StoreOf<PositionSettingFeature>
    
    public init(store: StoreOf<PositionSettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView
            
            // 탭 (특기/최애)
            tabView
                .padding(.top, 20)
                .padding(.horizontal, 20)
            
            // 메인 카드
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(store.availableStyles) { style in
                        PositionStyleCard(
                            style: style,
                            isSelected: store.selectedBestPosition == style || store.selectedFavoritePosition == style
                        )
                        .onTapGesture {
                            store.send(.view(.styleCardTapped(style)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            
            // 선택된 스타일 미리보기
            if store.selectedBestPosition != nil || store.selectedFavoritePosition != nil {
                selectedStylesPreview
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            
            // 완료 버튼
            Button {
                store.send(.view(.completeButtonTapped))
            } label: {
                Text(store.selectedBestPosition == nil ? "특기 선정 완료" : 
                     store.selectedTab == .top ? "특기 선정 완료" : "최애 선정 완료")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(store.canComplete ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!store.canComplete)
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .padding(.top, 16)
        }
        .background(Color(hex: "#F5F5F5"))
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 0) {
            Button {
                store.send(.view(.backButtonTapped))
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("포지션 설정")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button {
                store.send(.view(.resetButtonTapped))
            } label: {
                Text("내용에 하지")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#007AFF"))
            }
            .frame(width: 80, height: 44)
        }
        .padding(.horizontal, 4)
        .frame(height: 56)
        .background(Color.white)
    }
    
    // MARK: - Tab View
    
    private var tabView: some View {
        HStack(spacing: 0) {
            ForEach(StyleCategory.allCases, id: \.self) { category in
                TabButton(
                    title: category.displayName,
                    subtitle: category.subtitle,
                    isSelected: store.selectedTab == category
                ) {
                    store.send(.view(.tabSelected(category)))
                }
            }
        }
        .frame(height: 60)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Selected Styles Preview
    
    private var selectedStylesPreview: some View {
        HStack(spacing: 12) {
            if let best = store.selectedBestPosition {
                SmallStyleCard(style: best, label: "탑")
            }
            
            if let favorite = store.selectedFavoritePosition {
                SmallStyleCard(style: favorite, label: "가드")
            }
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
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : Color(hex: "#999999"))
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#CCCCCC"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(12)
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
            
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 80)
        .cornerRadius(12)
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
        PositionSettingView(
            store: Store(
                initialState: PositionSettingFeature.State()
            ) {
                PositionSettingFeature()
            }
        )
    }
}
