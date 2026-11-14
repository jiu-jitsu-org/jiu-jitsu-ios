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
    /// 비로그인 MY(#242) — 닉네임 대신 인사와 로그인 안내를 보이고, 고치는 버튼과 "..." 메뉴를 숨긴다.
    let isGuest: Bool
    /// 오른쪽 위 톱니바퀴(설정, #241). 커뮤니티에서 쌓아 연 MY에는 두지 않는다.
    let showsSettingsButton: Bool

    // Optimistic Update 입력 — 업로드/삭제 진행 중 표시
    let pendingProfileImageData: Data?
    let isProfileImageDeleting: Bool
    let isProfileImageBusy: Bool

    let onNicknameEditTapped: () -> Void
    let onGymInfoTapped: () -> Void
    let onMoreButtonTapped: () -> Void
    let onProfileImageEditTapped: () -> Void
    let onSettingsTapped: () -> Void

    // 기존 호출처 호환 유지를 위한 기본값 init
    public init(
        nickname: String,
        academyName: String?,
        profileImageUrl: String?,
        beltRank: BeltRank?,
        safeAreaTop: CGFloat,
        isOwner: Bool = false,
        isGuest: Bool = false,
        showsSettingsButton: Bool = false,
        pendingProfileImageData: Data? = nil,
        isProfileImageDeleting: Bool = false,
        isProfileImageBusy: Bool = false,
        onNicknameEditTapped: @escaping () -> Void,
        onGymInfoTapped: @escaping () -> Void,
        onMoreButtonTapped: @escaping () -> Void,
        onProfileImageEditTapped: @escaping () -> Void,
        onSettingsTapped: @escaping () -> Void = {}
    ) {
        self.nickname = nickname
        self.academyName = academyName
        self.profileImageUrl = profileImageUrl
        self.beltRank = beltRank
        self.safeAreaTop = safeAreaTop
        self.isOwner = isOwner
        self.isGuest = isGuest
        self.showsSettingsButton = showsSettingsButton
        self.pendingProfileImageData = pendingProfileImageData
        self.isProfileImageDeleting = isProfileImageDeleting
        self.isProfileImageBusy = isProfileImageBusy
        self.onNicknameEditTapped = onNicknameEditTapped
        self.onGymInfoTapped = onGymInfoTapped
        self.onMoreButtonTapped = onMoreButtonTapped
        self.onProfileImageEditTapped = onProfileImageEditTapped
        self.onSettingsTapped = onSettingsTapped
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
                    showsCameraButton: !isGuest,
                    onCameraTapped: onProfileImageEditTapped
                )

                if isGuest {
                    guestGreeting
                } else {
                    memberInfo
                }
            }

            topTrailingButtons
        }
    }

    // 비로그인 MY(#242): 닉네임·도장명 자리에 인사와 로그인 안내를 같은 글자·높이로 둔다.
    // 아래 여백은 도장명이 있을 때와 같아 벨트 카드가 같은 만큼 겹친다(MyProfileView overlapWithAcademyName).
    @ViewBuilder
    private var guestGreeting: some View {
        Text("반가워요")
            .font(Font.pretendard.title3)
            .foregroundStyle(Color.component.list.setting.background)
            .frame(height: 29)
            .padding(.top, 12)

        Text("로그인하고 내 프로필을 만들어 보세요")
            .font(Font.pretendard.bodyS)
            .foregroundStyle(Color.component.list.setting.background.opacity(0.7))
            .frame(height: 32)

        Spacer().frame(height: 84)
    }

    @ViewBuilder
    private var memberInfo: some View {
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
            .padding(.top, NameEditMetrics.academyRowGap)

            Spacer().frame(height: 84 - NameEditMetrics.academyRowGap)
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

    // 우측 상단 버튼 (safe area 상단을 피해서 배치) — "..."(관장 사범 인증) 오른쪽에 설정 톱니바퀴(#241).
    // 비로그인은 관장 사범 인증을 쓸 수 없어 "..."를 숨긴다(#242).
    private var topTrailingButtons: some View {
        HStack(spacing: 4) {
            if !isGuest {
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
            }

            if showsSettingsButton {
                Button {
                    onSettingsTapped()
                } label: {
                    Assets.Bottom.Icon.setting.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        // 띠 색 헤더 위라 흰색 — 커뮤니티에서 연 MY의 뒤로가기와 같은 색
                        .foregroundStyle(Color.component.list.setting.background)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
            }
        }
        .padding(.top, safeAreaTop + 12)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, alignment: .trailing)
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
    var showsCameraButton: Bool = true
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
            if showsCameraButton {
                cameraButton
                    .offset(x: 5, y: 4)
            }
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

// MARK: - 이름 줄(닉네임·도장명) + 수정 버튼

/// 이름 줄 치수(#313)
private enum NameEditMetrics {
    static let pencilSize: CGFloat = 16
    static let pencilGap: CGFloat = 4
    /// 두 줄의 캡슐이 붙지 않게 닉네임과 도장명 사이를 벌리는 만큼. 아래 여백에서 같은 만큼 빼 벨트 카드 자리는 그대로 둔다.
    static let academyRowGap: CGFloat = 8
    /// 글자 양옆에 비워 둘 폭 — 긴 이름이어도 캡슐이 화면 끝에 붙지 않게
    static let sideReserve: CGFloat = 40
}

/// 이름 한 줄 + 연필을 옅은 면 캡슐 하나(한 버튼)로 묶는다(#313).
/// 글자만 가운데에 두고 연필을 옆에 붙이면 줄이 오른쪽으로, 줄 전체를 가운데에 두면 글자가 왼쪽으로 쏠려 보인다.
/// 캡슐은 바깥 모양이 좌우 대칭이라 이름 길이와 상관없이 가운데로 보이고, 누르면 고치는 버튼임이 분명해진다.
/// 글자·연필 어디를 눌러도 같은 수정 화면을 연다(정책 2.1, #66).
private struct NameEditRow: View {
    let text: String
    let font: Font
    let textColor: Color
    let showsOwnerBadge: Bool
    let height: CGFloat
    let capsuleHeight: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        Button(action: onEditTapped) {
            HStack(spacing: 0) {
                if showsOwnerBadge {
                    Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 5)
                }
                Text(text)
                    .font(font)
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                Assets.Common.Icon.pencil.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: NameEditMetrics.pencilSize, height: NameEditMetrics.pencilSize)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .padding(.leading, NameEditMetrics.pencilGap)
            }
            // 연필 쪽이 가벼워 오른쪽 안쪽 여백을 조금 덜 준다 — 캡슐 안에서 글자 덩어리가 가운데로 보이게
            .padding(.leading, capsuleHeight * 0.42)
            .padding(.trailing, capsuleHeight * 0.34)
            .frame(height: capsuleHeight)
            .background(Capsule().fill(Color.white.opacity(0.16)))
            // 도장명 캡슐(26)은 낮아 누르는 칸을 위아래로 넓힌다 — 전 연필 버튼(32)보다 작아지지 않게
            .contentShape(Capsule().inset(by: -4))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, NameEditMetrics.sideReserve)
        .frame(height: height)
    }
}

/// 닉네임 + 수정 버튼 행
private struct NicknameEditRow: View {
    let nickname: String
    /// `true`이면 닉네임 왼쪽에 관장/사범 인증 뱃지를 표시한다.
    let isOwner: Bool
    let height: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        NameEditRow(
            text: nickname,
            font: Font.pretendard.title3,
            textColor: Color.component.list.setting.background,
            showsOwnerBadge: isOwner,
            height: height,
            capsuleHeight: 34,
            onEditTapped: onEditTapped
        )
    }
}

// MARK: - AcademyNameEditRow

/// 도장명 + 수정 버튼 행
private struct AcademyNameEditRow: View {
    let academyName: String
    let height: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        NameEditRow(
            text: academyName,
            font: Font.pretendard.bodyS,
            textColor: Color.component.list.setting.background.opacity(0.7),
            showsOwnerBadge: false,
            height: height,
            capsuleHeight: 26,
            onEditTapped: onEditTapped
        )
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
