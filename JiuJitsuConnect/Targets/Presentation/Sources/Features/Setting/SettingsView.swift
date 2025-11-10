//
//  SettingsView.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

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
        VStack {
            // MARK: - Header View
            
            List {
                // MARK: - 약관 및 정책 섹션
                Section {
                    Button(action: {
                        // TODO: 서비스 이용 약관 상세 로직 실행
                        print("서비스 이용 약관 상세 탭")
                    }) {
                        HStack {
                            SettingsRow(asset: Assets.Common.Icon.documents, text: "서비스 이용 약관")
                            Spacer()
                            Assets.Common.Icon.chevronRight.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                        }
                    }
                    
                    NavigationLink {
                        // TODO: 개인정보 처리 방침 화면으로 이동
                        Text("TODO: 개인정보 처리 방침 상세")
                    } label: {
                        SettingsRow(asset: Assets.Common.Icon.documents, text: "개인정보 처리 방침")
                    }
                }
                
                // MARK: - 버전 정보 섹션
                Section {
                    HStack {
                        SettingsRow(asset: Assets.Common.Icon.version, text: "버전 정보")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                }
                
                // MARK: - 계정 관리 섹션
                Section {
                    Button(action: {
                        // TODO: 로그아웃 로직 실행
                        print("로그아웃 버튼 탭")
                    }) {
                        HStack {
                            SettingsRow(asset: Assets.Common.Icon.logOut, text: "로그아웃")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                    }
                    
                    Button(action: {
                        // TODO: 회원 탈퇴 로직 실행
                        print("회원 탈퇴 버튼 탭")
                    }) {
                        HStack {
                            SettingsRow(asset: Assets.Common.Icon.secession, text: "회원 탈퇴")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped) // 카드 형태의 그룹 스타일 적용
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline) // 작은 네비게이션 타이틀
        }
    }
}

// MARK: - Reusable Row View
private struct SettingsRow: View {
    let asset: ImageAsset
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            asset.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
            Text(text)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.text)
        }
    }
}
