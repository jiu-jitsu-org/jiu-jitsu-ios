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
    
    private var appVersion: String { "99.99" }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: Style.sectionSpacing) {
                    // MARK: - 약관 및 정책 섹션
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.documents, text: "서비스 이용 약관") {
                            store.send(.termsButtonTapped)
                        }
                        SettingsInteractiveRow(asset: Assets.Common.Icon.documents, text: "개인정보 처리 방침") {
                            store.send(.privacyPolicyButtonTapped)
                        }
                    }
                    
                    // MARK: - 버전 정보 섹션
                    SettingsSection {
                        HStack {
                            SettingsRowContent(asset: Assets.Common.Icon.version, text: "버전 정보")
                            Spacer()
                            Text(appVersion)
                                .font(Font.pretendard.captionM)
                                .foregroundStyle(Color.component.list.setting.valueText)
                        }
                        .frame(minHeight: Style.rowHeight)
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: - 계정 관리 섹션
                    SettingsSection {
                        SettingsInteractiveRow(asset: Assets.Common.Icon.logOut, text: "로그아웃") {
                            store.send(.logoutButtonTapped)
                        }
                        SettingsInteractiveRow(asset: Assets.Common.Icon.secession, text: "회원 탈퇴") {
                            store.send(.withdrawalButtonTapped)
                        }
                    }
                }
                .padding(.horizontal, Style.horizontalPadding)
                .padding(.vertical, Style.verticalPadding)
            }
            .background(Color.component.background.default)
        }
        .appAlert(
            isPresented: Binding(
                get: { store.alert != nil },
                set: { if !$0 { store.send(.alertDismissed) } }
            ),
            configuration: alertConfiguration(for: store.alert)
        )
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { store.send(.backButtonTapped) }) {
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
            
            Text("설정")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
            
            Spacer()
            
            Rectangle()
                .fill(.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
        .background(Color.component.background.default.ignoresSafeArea(edges: .top))
    }
    
    // MARK: - Alert Configuration Helper
    private func alertConfiguration(for alertType: SettingsFeature.State.Alert?) -> AppAlertConfiguration {
        switch alertType {
        case .logout:
            return .init(
                title: "로그아웃",
                message: "로그아웃 하시겠습니까?",
                primaryButton: .init(title: "로그아웃", style: .primary, action: { store.send(.alertConfirmButtonTapped) }),
                secondaryButton: .init(title: "취소", style: .neutral, action: { store.send(.alertDismissed) })
            )
        case .withdrawal:
            return .init(
                title: "회원 탈퇴",
                message: "30일 뒤 계정이 영구 삭제됩니다. 작성한 게시물과 댓글은 익명으로 남으며, 기간 내 재로그인 시 탈퇴가 취소됩니다.",
                primaryButton: .init(title: "탈퇴하기", style: .destructive, action: { store.send(.alertConfirmButtonTapped) }),
                secondaryButton: .init(title: "취소", style: .neutral, action: { store.send(.alertDismissed) })
            )
        case .none:
            // Alert가 보이지 않을 때를 위한 기본값. 내용은 중요하지 않습니다.
            return .init(title: "", message: "", primaryButton: .init(title: "", action: {}), secondaryButton: nil)
        }
    }
}

// MARK: - Reusable Section Container
private struct SettingsSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: Style.rowSpacing) {
            content
        }
        .padding(.vertical, Style.sectionVerticalPadding)
        .background(Color.component.list.setting.background)
        .clipShape(RoundedRectangle(cornerRadius: Style.sectionCornerRadius))
    }
}

// MARK: - Reusable Row Views
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
        .frame(minHeight: Style.rowHeight) // 고정 높이 대신 최소 높이 사용
        .padding(.leading, 16)
        .padding(.trailing, 8)
    }
}

// MARK: - SwiftUI Preview
import Domain

#Preview("Settings View") {
    SettingsView(
        store: Store(initialState: SettingsFeature.State(authInfo: AuthInfo(accessToken: nil,
                                                                            refreshToken: nil,
                                                                            tempToken: "test-temp-token",
                                                                            isNewUser: true,
                                                                            userInfo: nil))) {
            SettingsFeature()
            // _printChanges()를 붙이면 Preview에서 버튼을 눌렀을 때
            // 어떤 Action이 발생하는지 콘솔에서 확인할 수 있어 유용합니다.
                ._printChanges()
        }
    )
}
