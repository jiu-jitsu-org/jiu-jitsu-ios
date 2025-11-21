//
//  SettingsView.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import CoreKit

private enum Style {
    static let headerHeight: CGFloat = 44
    
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
    
    static let sectionSpacing: CGFloat = 16
    static let sectionCornerRadius: CGFloat = 16
    static let sectionVerticalPadding: CGFloat = 8
    
    static let rowSpacing: CGFloat = 4
    static let rowHeight: CGFloat = 40
}

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    // 앱의 버전 정보를 가져오는 Helper
    private var appVersion: String {
        // 이미지와 동일하게 보이기 위해 하드코딩합니다.
        // 실제 앱에서는 아래의 동적 코드를 사용하는 것이 좋습니다.
        return "99.99"
        /*
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "N/A"
        }
        return version
        */
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header View
            headerView
            
            ScrollView {
                VStack(spacing: Style.sectionSpacing) {
                    // MARK: - 약관 및 정책 섹션
                    VStack(spacing: Style.rowSpacing) {
                        SettingsInteractiveRow(
                            asset: Assets.Common.Icon.documents,
                            text: "서비스 이용 약관",
                            action: {
                                Log.trace("서비스 이용 약관 상세 버튼 탭", category: .debug)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: Style.rowHeight)
                        
                        SettingsInteractiveRow(
                            asset: Assets.Common.Icon.documents,
                            text: "개인정보 처리 방침",
                            action: {
                                Log.trace("개인정보 처리 방침 상세 탭", category: .debug)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: Style.rowHeight)
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .padding(.vertical, Style.sectionVerticalPadding)
                    .background(Color.component.list.setting.background)
                    .clipShape(RoundedRectangle(cornerRadius: Style.sectionCornerRadius))
                    
                    // MARK: - 버전 정보 섹션
                    VStack {
                        HStack {
                            SettingsRowContent(asset: Assets.Common.Icon.version, text: "버전 정보")
                            Spacer()
                            Text(appVersion)
                                .font(Font.pretendard.captionM)
                                .foregroundStyle(Color.component.list.setting.valueText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: Style.rowHeight)
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .padding(.vertical, Style.sectionVerticalPadding)
                    .background(Color.component.list.setting.background)
                    .clipShape(RoundedRectangle(cornerRadius: Style.sectionCornerRadius))
                    
                    // MARK: - 계정 관리 섹션
                    VStack(spacing: Style.rowSpacing) {
                        SettingsInteractiveRow(
                            asset: Assets.Common.Icon.logOut,
                            text: "로그아웃",
                            action: {
                                Log.trace("로그아웃 탭", category: .debug)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: Style.rowHeight)
                        
                        SettingsInteractiveRow(
                            asset: Assets.Common.Icon.secession,
                            text: "회원 탈퇴",
                            action: {
                                Log.trace("회원 탈퇴 탭", category: .debug)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: Style.rowHeight)
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .padding(.vertical, Style.sectionVerticalPadding)
                    .background(Color.component.list.setting.background)
                    .clipShape(RoundedRectangle(cornerRadius: Style.sectionCornerRadius))
                }
                .padding(.vertical, Style.verticalPadding)
            }
//            .bounces(false) // 2. 스크롤뷰 바운스 효과 제거 (iOS 16.4 이상)
            .background(Color.component.background.default) // 전체 배경색
        }
        .navigationBarHidden(true) // 네비게이션 바를 완전히 숨김
        .ignoresSafeArea(edges: .bottom) // 하단 홈 인디케이터 영역까지 배경색 채우기
    }
    
    private var headerView: some View {
        HStack {
            // 뒤로가기 버튼
            Button(action: {
                Log.trace("뒤로가기 탭", category: .debug)
            }) {
                ZStack {
                    Assets.Common.Icon.chevronLeft.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 타이틀
            Text("설정")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
            
            Spacer()
            
            // 타이틀 중앙 정렬을 위한 투명한 Placeholder
            Rectangle()
                .fill(.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top)) // 헤더 배경색 (상단 Safe Area까지 확장)
    }
}

// MARK: - Reusable Row View
private struct SettingsRowContent: View {
    let asset: ImageAsset
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            asset.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.component.list.setting.leadingIcon)
            Text(text)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.text)
        }
    }
}

private struct SettingsInteractiveRow: View {
    let asset: ImageAsset
    let text: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            SettingsRowContent(asset: asset, text: text)
            Spacer()
            Button(action: action) {
                ZStack {
                    Assets.Common.Icon.chevronRight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                }
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
