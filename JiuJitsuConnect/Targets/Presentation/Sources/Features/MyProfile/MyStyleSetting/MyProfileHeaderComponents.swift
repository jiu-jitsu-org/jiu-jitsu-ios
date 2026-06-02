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
    /// 관장/사범 인증 완료 여부 — `true`이면 닉네임 왼쪽에 인증 뱃지 표시
    let isOwner: Bool

    // Optimistic Update 입력 — 업로드/삭제 진행 중 표시
    let pendingProfileImageData: Data?
    let isProfileImageDeleting: Bool
    let isProfileImageBusy: Bool

    let onNicknameEditTapped: () -> Void
    let onGymInfoTapped: () -> Void
    let onMoreButtonTapped: () -> Void
    let onProfileImageEditTapped: () -> Void

    // 기존 호출처 호환 유지를 위한 기본값 init
    public init(
        nickname: String,
        academyName: String?,
        profileImageUrl: String?,
        beltRank: BeltRank?,
        safeAreaTop: CGFloat,
        isOwner: Bool = false,
        pendingProfileImageData: Data? = nil,
        isProfileImageDeleting: Bool = false,
        isProfileImageBusy: Bool = false,
        onNicknameEditTapped: @escaping () -> Void,
        onGymInfoTapped: @escaping () -> Void,
        onMoreButtonTapped: @escaping () -> Void,
        onProfileImageEditTapped: @escaping () -> Void
    ) {
        self.nickname = nickname
        self.academyName = academyName
        self.profileImageUrl = profileImageUrl
        self.beltRank = beltRank
        self.safeAreaTop = safeAreaTop
        self.isOwner = isOwner
        self.pendingProfileImageData = pendingProfileImageData
        self.isProfileImageDeleting = isProfileImageDeleting
        self.isProfileImageBusy = isProfileImageBusy
        self.onNicknameEditTapped = onNicknameEditTapped
        self.onGymInfoTapped = onGymInfoTapped
        self.onMoreButtonTapped = onMoreButtonTapped
        self.onProfileImageEditTapped = onProfileImageEditTapped
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .top) {
            // 배경색 (벨트 등급에 따라 변경)
            beltRank.headerBackgroundColor
                .animation(.easeInOut(duration: 0.3), value: beltRank)

            VStack(spacing: 0) {
                // 상단 여백
                Spacer().frame(height: safeAreaTop + 68)

                // 프로필 이미지
                ProfileImageView(
                    profileImageUrl: profileImageUrl,
                    pendingImageData: pendingProfileImageData,
                    isDeleting: isProfileImageDeleting,
                    isBusy: isProfileImageBusy,
                    size: 90,
                    cornerRadius: 24,
                    iconSize: 64,
                    onCameraTapped: onProfileImageEditTapped
                )

                // 닉네임 + 수정 버튼
                NicknameEditRow(
                    nickname: nickname,
                    isOwner: isOwner,
                    height: 29,
                    onEditTapped: onNicknameEditTapped
                )
                .padding(.top, 12)

                // 도장명 + 수정 버튼 (있는 경우)
                if let academyName = academyName {
                    AcademyNameEditRow(
                        academyName: academyName,
                        height: 32,
                        onEditTapped: onGymInfoTapped
                    )

                    Spacer().frame(height: 84)
                }

                // "도장 정보 입력하기" 버튼 (도장명이 없을 때만)
                if academyName == nil {
                    Button {
                        onGymInfoTapped()
                    } label: {
                        AppButtonConfiguration(title: "도장 정보 입력하기", size: .small)
                    }
                    .appButtonStyle(.tint, size: .small, height: 32)
                    .padding(.top, 15)

                    Spacer().frame(height: 82.49)
                }
            }

            // 우측 상단 "..." 버튼 (safe area 상단을 피해서 배치)
            Button {
                onMoreButtonTapped()
            } label: {
                Assets.MyProfile.Icon.menu.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.component.button.inverted.defaultBg)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, safeAreaTop + 12)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - ProfileImageView

/// 프로필 이미지 컴포넌트.
///
/// 표시 우선순위:
/// 1. `isDeleting`이면 기본 아이콘 (삭제 진행 중 즉시 반영)
/// 2. `pendingImageData`가 있으면 로컬 미리보기 (Optimistic Update)
/// 3. `profileImageUrl`이 유효한 http/https면 AsyncImage
/// 4. 그 외 기본 아이콘
///
/// `isBusy`가 true면 이미지를 살짝 흐리게 + 중앙에 스피너를 띄워 "처리 중"을 시각화한다.
private struct ProfileImageView: View {
    let profileImageUrl: String?
    let pendingImageData: Data?
    let isDeleting: Bool
    let isBusy: Bool
    let size: CGFloat
    let cornerRadius: CGFloat
    let iconSize: CGFloat
    let onCameraTapped: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.component.list.setting.background)
                .frame(width: size, height: size)

            imageContent
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .opacity(isBusy ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isBusy)

            if isBusy {
                busyOverlay
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            cameraButton
                .offset(x: 5, y: 4)
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if isDeleting {
            // 삭제 진행 중 — 헤더를 즉시 기본 상태로 전환
            defaultProfileIcon
        } else if let profileImageUrl = profileImageUrl,
                  let url = URL(string: profileImageUrl),
                  url.scheme == "https" || url.scheme == "http" {
            // 서버 URL이 있는 경로. 업로드 성공 직후엔 새 URL의 AsyncImage가 `.empty`로
            // 시작하면서 잠깐 기본 아이콘이 깜빡일 수 있는데, 그 사이를 로컬 미리보기로 덮어
            // 사용자에게는 무중단 전환처럼 보이도록 한다.
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    pendingPreviewOrDefault
                @unknown default:
                    pendingPreviewOrDefault
                }
            }
        } else if let data = pendingImageData, let uiImage = UIImage(data: data) {
            // URL이 아직 없거나(예: 최초 등록 진행 중) 비http인 경우 — 로컬 미리보기
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            defaultProfileIcon
        }
    }

    @ViewBuilder
    private var pendingPreviewOrDefault: some View {
        if let data = pendingImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            defaultProfileIcon
        }
    }

    private var busyOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.18))
                .frame(width: size, height: size)

            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.component.list.setting.background)
                .scaleEffect(1.1)
        }
        .transition(.opacity)
    }

    private var defaultProfileIcon: some View {
        Assets.Common.Icon.profile.swiftUIImage
            .resizable()
            .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
            .frame(width: iconSize, height: iconSize)
    }

    private var cameraButton: some View {
        Button(action: onCameraTapped) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.component.button.neutral.defaultBg)
                    .frame(width: 36, height: 36)

                Assets.MyProfile.Icon.camera.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NicknameEditRow

/// 닉네임 + 수정 버튼 행
private struct NicknameEditRow: View {
    let nickname: String
    /// `true`이면 닉네임 왼쪽에 관장/사범 인증 뱃지를 표시한다.
    let isOwner: Bool
    let height: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // FIXME: 임시 뱃지 — 디자인 확정 후 교체 예정
            if isOwner {
                Text("관장")
                    .font(Font.pretendard.labelS)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
                    .padding(.trailing, 6)
            }

            Text(nickname)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.list.setting.background)

            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(width: 32, height: 32)
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

    var body: some View {
        HStack(spacing: 0) {
            Text(academyName)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.background.opacity(0.7))

            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(width: 32, height: 32)
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
        onGymInfoTapped: { },
        onMoreButtonTapped: { },
        onProfileImageEditTapped: { }
    )
    .background(Color.component.background.default)
}

#Preview("MyProfileHeaderView - 관장/사범 인증 (OWNER)") {
    MyProfileHeaderView(
        nickname: "그라시에 관장",
        academyName: "그라시에 바하 주짓수",
        profileImageUrl: nil,
        beltRank: .black,
        safeAreaTop: 47,
        isOwner: true,
        onNicknameEditTapped: { },
        onGymInfoTapped: { },
        onMoreButtonTapped: { },
        onProfileImageEditTapped: { }
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
        onGymInfoTapped: { },
        onMoreButtonTapped: { },
        onProfileImageEditTapped: { }
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
                    onGymInfoTapped: { },
                    onMoreButtonTapped: { },
                    onProfileImageEditTapped: { }
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
