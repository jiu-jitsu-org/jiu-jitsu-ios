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
    let beltStripe: BeltStripe?
    /// 헤더 바탕 무늬(#320) — 띠가 있을 때만 깐다.
    let pattern: MyHeaderPattern
    /// 오를 때마다 사진 링이 한 번 돈다(#320) — MyProfileFeature.beltEntranceTrigger
    let beltEntranceTrigger: Int
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
    /// 헤더 빈 바탕을 누르면 무늬 고르기 시트를 연다(#320). 띠가 없으면 무늬가 없어 열지 않는다.
    let onBackgroundTapped: () -> Void

    /// 사진(링 포함) 위 여백 — safe area 아래. 무늬가 사진 가운데를 기준으로 그려져 함께 쓴다.
    private static let avatarTopSpacing: CGFloat = 57

    // 기존 호출처 호환 유지를 위한 기본값 init
    public init(
        nickname: String,
        academyName: String?,
        profileImageUrl: String?,
        beltRank: BeltRank?,
        beltStripe: BeltStripe? = nil,
        pattern: MyHeaderPattern = .oss,
        beltEntranceTrigger: Int = 0,
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
        onSettingsTapped: @escaping () -> Void = {},
        onBackgroundTapped: @escaping () -> Void = {}
    ) {
        self.nickname = nickname
        self.academyName = academyName
        self.profileImageUrl = profileImageUrl
        self.beltRank = beltRank
        self.beltStripe = beltStripe
        self.pattern = pattern
        self.beltEntranceTrigger = beltEntranceTrigger
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
        self.onBackgroundTapped = onBackgroundTapped
    }

    private var foreground: Color { beltRank.myHeaderForeground }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // 상단 여백
                Spacer().frame(height: safeAreaTop + Self.avatarTopSpacing)

                // 프로필 이미지 + 띠 링(#320)
                ProfileImageView(
                    profileImageUrl: profileImageUrl,
                    pendingImageData: pendingProfileImageData,
                    isDeleting: isProfileImageDeleting,
                    isBusy: isProfileImageBusy,
                    beltRank: beltRank,
                    beltStripe: beltStripe,
                    entranceTrigger: beltEntranceTrigger,
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
        .background { headerBackground }
    }

    // 띠 색 바탕 + 같은 계열 색 무늬(#320). 글자·버튼이 없는 빈 곳을 누르면 무늬 고르기.
    private var headerBackground: some View {
        GeometryReader { proxy in
            let avatarCenterY = safeAreaTop + Self.avatarTopSpacing + MyBeltRing.box / 2
            ZStack {
                beltRank.myHeaderColor
                if let beltRank {
                    MyHeaderPatternView(
                        pattern: pattern,
                        beltRank: beltRank,
                        anchor: UnitPoint(x: 0.5, y: proxy.size.height > 0 ? avatarCenterY / proxy.size.height : 0)
                    )
                    .equatable()
                    .id(pattern)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: beltRank)
            .animation(.easeInOut(duration: 0.3), value: pattern)
            .contentShape(Rectangle())
            .onTapGesture {
                guard canPickPattern else { return }
                onBackgroundTapped()
            }
            // 빈 바탕 누르기는 VoiceOver로 찾을 수 없어 버튼으로 알린다.
            .accessibilityElement()
            .accessibilityLabel("배경 고르기")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onBackgroundTapped() }
            .accessibilityHidden(!canPickPattern)
        }
    }

    private var canPickPattern: Bool { beltRank != nil && !isGuest }

    // 비로그인 MY(#242): 닉네임·도장명 자리에 인사와 로그인 안내를 같은 글자·높이로 둔다.
    // 아래 여백은 도장명이 있을 때와 같아 벨트 카드가 같은 만큼 겹친다(MyProfileView overlapWithAcademyName).
    @ViewBuilder
    private var guestGreeting: some View {
        Text("반가워요")
            .font(Font.pretendard.title3)
            .foregroundStyle(foreground)
            .frame(height: 29)
            .padding(.top, 10)

        Text("로그인하고 내 프로필을 만들어 보세요")
            .font(Font.pretendard.bodyS)
            .foregroundStyle(foreground.opacity(0.7))
            .frame(height: 32)

        Spacer().frame(height: 84)
    }

    @ViewBuilder
    private var memberInfo: some View {
        // 닉네임 + 수정 버튼
        NicknameEditRow(
            nickname: nickname,
            isOwner: isOwner,
            foreground: foreground,
            height: 29,
            onEditTapped: onNicknameEditTapped
        )
        .padding(.top, 10)

        // 도장명 + 수정 버튼 (있는 경우)
        if let academyName = academyName {
            AcademyNameEditRow(
                academyName: academyName,
                foreground: foreground,
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

    // 우측 상단 버튼 (safe area 상단을 피해서 배치) — "..."(관장 사범 인증) 오른쪽에 설정 톱니바퀴(#241).
    // 비로그인은 관장 사범 인증을 쓸 수 없어 "..."를 숨긴다(#242).
    private var topTrailingButtons: some View {
        HStack(spacing: 4) {
            if !isGuest {
                Button {
                    onMoreButtonTapped()
                } label: {
                    Assets.MyProfile.Icon.menu.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(foreground)
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
                        // 띠 색 헤더 위 — 커뮤니티에서 연 MY의 뒤로가기와 같은 색(밝은 띠면 어둡게)
                        .foregroundStyle(foreground)
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
    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    let entranceTrigger: Int
    let iconSize: CGFloat
    var showsCameraButton: Bool = true
    let onCameraTapped: () -> Void

    /// 사진·링을 누를 때마다 링이 커지며 다시 두 바퀴 돈다(#338). 카메라 버튼은 위에 겹친 따로 된 버튼이라 올리지 않는다.
    @State private var replayTrigger = 0

    var body: some View {
        MyBeltRingView(
            beltRank: beltRank,
            beltStripe: beltStripe,
            entranceTrigger: entranceTrigger,
            replayTrigger: replayTrigger
        ) {
            ZStack {
                Color.component.list.setting.background

                imageContent
                    .opacity(isBusy ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isBusy)

                if isBusy {
                    busyOverlay
                }
            }
        }
        .contentShape(Circle())
        .onTapGesture { replayTrigger += 1 }
        // VoiceOver에서도 같은 다시 보기를 실행한다. 동작 줄이기에선 MyBeltRingView가 움직이지 않는다.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("띠 링 다시 보기")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { replayTrigger += 1 }
        // 오른쪽 아래(135°)는 링의 띠 끝 칸·그랄 자리라, 카메라 버튼은 거울 자리인 왼쪽 아래에 둔다.
        .overlay(alignment: .bottomLeading) {
            if showsCameraButton {
                // 터치 영역 44 — 보이는 버튼(36)은 링 모서리 그대로 두고 바깥으로 4씩 넓힌다.
                cameraButton
                    .offset(x: -4, y: 4)
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
            Color.black.opacity(0.18)

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
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("프로필 사진 수정")
    }
}

// MARK: - NicknameEditRow

/// 닉네임 + 수정 버튼 행
private struct NicknameEditRow: View {
    let nickname: String
    /// `true`이면 닉네임 왼쪽에 관장/사범 인증 뱃지를 표시한다.
    let isOwner: Bool
    let foreground: Color
    let height: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if isOwner {
                Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 5)
            }

            // 닉네임 텍스트도 수정 진입 영역(정책 2.1, #66)
            Button(action: onEditTapped) {
                Text(nickname)
                    .font(Font.pretendard.title3)
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.plain)

            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(foreground.opacity(0.5))
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .frame(height: height)
        .padding(.horizontal, 20)
    }
}

// MARK: - AcademyNameEditRow

/// 도장명 + 수정 버튼 행
private struct AcademyNameEditRow: View {
    let academyName: String
    let foreground: Color
    let height: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(academyName)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(foreground.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)

            Button(action: onEditTapped) {
                ZStack {
                    Assets.Common.Icon.pencil.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(foreground.opacity(0.5))
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .frame(height: height)
        .padding(.horizontal, 20)
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
