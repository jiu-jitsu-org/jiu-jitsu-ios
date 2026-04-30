//
//  MyProfileHeaderComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - MyProfileHeaderView

/// 프로필 헤더 섹션
///
/// 배경색, 프로필 이미지, 닉네임, 도장명, 버튼을 포함하는 헤더 영역입니다.
public struct MyProfileHeaderView: View {
    // MARK: - Properties
    
    let nickname: String
    let academyName: String?
    let profileImageUrl: String?
    let beltRank: BeltRank?
    let safeAreaTop: CGFloat
    
    let onNicknameEditTapped: () -> Void
    let onGymInfoTapped: () -> Void
    
    // MARK: - Metrics
    
    private enum Metrics {
        static let topPadding: CGFloat = 68
        static let bottomPaddingWithButton: CGFloat = 82.49
        static let bottomPaddingWithAcademyName: CGFloat = 84
        
        static let profileImageSize: CGFloat = 90
        static let profileImageCornerRadius: CGFloat = 24
        static let profileIconSize: CGFloat = 64
        
        static let nicknameHeight: CGFloat = 29
        static let nicknameTopPadding: CGFloat = 12
        
        static let academyNameHeight: CGFloat = 32
        
        static let buttonTopPadding: CGFloat = 15
        static let buttonHeight: CGFloat = 32
        
        static let editButtonSize: CGFloat = 32
        static let editIconSize: CGFloat = 16
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .top) {
            // 배경색 (벨트 등급에 따라 변경)
            beltRank.headerBackgroundColor
                .animation(.easeInOut(duration: 0.3), value: beltRank)

            VStack(spacing: 0) {
                // 상단 여백
                Spacer().frame(height: safeAreaTop + Metrics.topPadding)
                
                // 프로필 이미지
                ProfileImageView(
                    profileImageUrl: profileImageUrl,
                    size: Metrics.profileImageSize,
                    cornerRadius: Metrics.profileImageCornerRadius,
                    iconSize: Metrics.profileIconSize
                )
                
                // 닉네임 + 수정 버튼
                NicknameEditRow(
                    nickname: nickname,
                    height: Metrics.nicknameHeight,
                    onEditTapped: onNicknameEditTapped
                )
                .padding(.top, Metrics.nicknameTopPadding)
                
                // 도장명 + 수정 버튼 (있는 경우)
                if let academyName = academyName {
                    AcademyNameEditRow(
                        academyName: academyName,
                        height: Metrics.academyNameHeight,
                        onEditTapped: onGymInfoTapped
                    )
                    
                    Spacer().frame(height: Metrics.bottomPaddingWithAcademyName)
                }
                
                // "도장 정보 입력하기" 버튼 (도장명이 없을 때만)
                if academyName == nil {
                    Button {
                        onGymInfoTapped()
                    } label: {
                        AppButtonConfiguration(title: "도장 정보 입력하기", size: .small)
                    }
                    .appButtonStyle(.tint, size: .small, height: Metrics.buttonHeight)
                    .padding(.top, Metrics.buttonTopPadding)

                    Spacer().frame(height: Metrics.bottomPaddingWithButton)
                }
            }
        }
    }
}

// MARK: - ProfileImageView

/// 프로필 이미지 컴포넌트
private struct ProfileImageView: View {
    let profileImageUrl: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    let iconSize: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.component.list.setting.background)
                .frame(width: size, height: size)
            
            if let profileImageUrl = profileImageUrl,
               let url = URL(string: profileImageUrl),
               url.scheme == "https" || url.scheme == "http" {
                // 실제 프로필 이미지
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    case .failure, .empty:
                        defaultProfileIcon
                    @unknown default:
                        defaultProfileIcon
                    }
                }
            } else {
                // 기본 아이콘
                defaultProfileIcon
            }
        }
    }
    
    private var defaultProfileIcon: some View {
        Assets.Common.Icon.profile.swiftUIImage
            .resizable()
            .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
            .frame(width: iconSize, height: iconSize)
    }
}

// MARK: - NicknameEditRow

/// 닉네임 + 수정 버튼 행
private struct NicknameEditRow: View {
    let nickname: String
    let height: CGFloat
    let onEditTapped: () -> Void
    
    private enum Metrics {
        static let editButtonSize: CGFloat = 32
        static let editIconSize: CGFloat = 16
        static let editIconOpacity: CGFloat = 0.5
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(nickname)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.list.setting.background)
            
            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metrics.editIconSize, height: Metrics.editIconSize)
                        .foregroundStyle(Color.white.opacity(Metrics.editIconOpacity))
                }
                .frame(width: Metrics.editButtonSize, height: Metrics.editButtonSize)
            }
            .buttonStyle(.plain)
        }
        .frame(height: height)
    }
}

// MARK: - AcademyNameEditRow

/// 도장명 + 수정 버튼 행
private struct AcademyNameEditRow: View {
    let academyName: String
    let height: CGFloat
    let onEditTapped: () -> Void
    
    private enum Metrics {
        static let editButtonSize: CGFloat = 32
        static let editIconSize: CGFloat = 16
        static let editIconOpacity: CGFloat = 0.5
        static let textOpacity: CGFloat = 0.7
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(academyName)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.background.opacity(Metrics.textOpacity))
            
            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metrics.editIconSize, height: Metrics.editIconSize)
                        .foregroundStyle(Color.white.opacity(Metrics.editIconOpacity))
                }
                .frame(width: Metrics.editButtonSize, height: Metrics.editButtonSize)
            }
            .buttonStyle(.plain)
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview("MyProfileHeaderView - 도장명 있음") {
    MyProfileHeaderView(
        nickname: "주짓수 러버",
        academyName: "그라시에 바하 주짓수",
        profileImageUrl: nil,
        beltRank: .blue,
        safeAreaTop: 47,
        onNicknameEditTapped: { },
        onGymInfoTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("MyProfileHeaderView - 도장명 없음") {
    MyProfileHeaderView(
        nickname: "주짓수 초보",
        academyName: nil,
        profileImageUrl: nil,
        beltRank: .white,
        safeAreaTop: 47,
        onNicknameEditTapped: { },
        onGymInfoTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("MyProfileHeaderView - 벨트 변경") {
    struct BeltChangePreview: View {
        @State private var selectedBelt: BeltRank = .white

        var body: some View {
            VStack(spacing: 0) {
                MyProfileHeaderView(
                    nickname: "주짓수 러버",
                    academyName: "그라시에 바하 주짓수",
                    profileImageUrl: nil,
                    beltRank: selectedBelt,
                    safeAreaTop: 47,
                    onNicknameEditTapped: { },
                    onGymInfoTapped: { }
                )
                
                Picker("벨트", selection: $selectedBelt) {
                    Text("화이트").tag(BeltRank.white)
                    Text("블루").tag(BeltRank.blue)
                    Text("퍼플").tag(BeltRank.purple)
                    Text("브라운").tag(BeltRank.brown)
                    Text("블랙").tag(BeltRank.black)
                }
                .pickerStyle(.segmented)
                .padding()
            }
        }
    }
    
    return BeltChangePreview()
}
