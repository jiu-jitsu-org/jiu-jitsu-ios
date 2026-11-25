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
    /// "..." 메뉴의 '관장 사범 인증'을 고름.
    let onInstructorVerificationTapped: () -> Void
    let onProfileImageEditTapped: () -> Void
    let onSettingsTapped: () -> Void
    /// 헤더 빈 바탕을 누르면 무늬 고르기 시트를 연다(#320). 띠가 없으면 무늬가 없어 열지 않는다.
    let onBackgroundTapped: () -> Void
    /// 서버 사진이 실제로 그려짐(#157). 업로드 뒤 새 사진이 보이면 겹쳐 둔 로컬 미리보기를 걷는다.
    let onProfileImageDisplayed: (String) -> Void

    /// 사진(링 포함) 위 여백 — safe area 아래. 무늬가 사진 가운데를 기준으로 그려져 함께 쓴다.
    /// 남의 프로필(#337)도 같은 자리에 사진을 둔다.
    static let avatarTopSpacing: CGFloat = 57

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
        onInstructorVerificationTapped: @escaping () -> Void,
        onProfileImageEditTapped: @escaping () -> Void,
        onSettingsTapped: @escaping () -> Void = {},
        onBackgroundTapped: @escaping () -> Void = {},
        onProfileImageDisplayed: @escaping (String) -> Void = { _ in }
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
        self.onInstructorVerificationTapped = onInstructorVerificationTapped
        self.onProfileImageEditTapped = onProfileImageEditTapped
        self.onSettingsTapped = onSettingsTapped
        self.onBackgroundTapped = onBackgroundTapped
        self.onProfileImageDisplayed = onProfileImageDisplayed
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
                    onCameraTapped: onProfileImageEditTapped,
                    onRemoteImageDisplayed: onProfileImageDisplayed
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
        MyHeaderBackground(
            beltRank: beltRank,
            pattern: pattern,
            avatarCenterY: safeAreaTop + Self.avatarTopSpacing + MyBeltRing.box / 2
        )
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
                // 시스템 메뉴라 바깥을 누르거나 스크롤 · 탭을 옮기면 닫히고 VoiceOver도 메뉴로 읽는다(#399).
                // 직접 그린 오버레이는 "..."를 다시 눌러야만 닫혔다.
                Menu {
                    Button("관장 사범 인증") { onInstructorVerificationTapped() }
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
                .accessibilityLabel("더 보기")
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

// MARK: - MyHeaderBackground

/// 띠 색 바탕 + 같은 계열 색 무늬(#320). MY와 남의 프로필(#337) 상단이 같이 쓴다. 띠가 없으면 기본색만 깐다.
struct MyHeaderBackground: View {
    let beltRank: BeltRank?
    let pattern: MyHeaderPattern
    /// 바탕 위에서 사진 가운데까지 높이 — 무늬를 이 점 기준으로 깐다.
    let avatarCenterY: CGFloat

    var body: some View {
        GeometryReader { proxy in
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
        }
    }
}

// MARK: - ProfileImageView

/// 프로필 이미지 컴포넌트.
///
/// 표시 우선순위:
/// 1. `isDeleting`이면 기본 아이콘 (삭제 진행 중 즉시 반영)
/// 2. `pendingImageData`가 있으면 로컬 미리보기 (Optimistic Update). 서버 사진 위에 겹쳐,
///    업로드 중에는 예전 사진 대신 새 사진이 보이고 새 URL을 받아 오는 동안에도 깜빡이지 않는다(#157)
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
    let onRemoteImageDisplayed: (String) -> Void

    /// 사진·링을 누를 때마다 링이 커지며 다시 두 바퀴 돈다(#338). 사진 아래 수정 띠는 따로 된 버튼이라 누르면 링을 올리지 않는다.
    @State private var replayTrigger = 0

    /// 서버 사진이 실제로 그려진 주소. 불러오는 중·실패면 이 주소와 달라 수정 띠를 옅은 회색으로 둔다.
    @State private var loadedPhotoURL: URL?

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
            // VoiceOver에선 사진만 '다시 보기' 버튼으로 읽는다. 수정 띠는 아래 overlay라 따로 읽힌다.
            // 동작 줄이기에선 MyBeltRingView가 움직이지 않는다.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("띠 링 다시 보기")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { replayTrigger += 1 }
            // 사진 원 안쪽 아래를 띠로 덮는다 — MyBeltRingView가 사진을 원으로 잘라 링·틈은 덮지 않고,
            // 다시 보기로 커질 때도 사진과 함께 커진다(#340).
            .overlay(alignment: .bottom) {
                if showsCameraButton {
                    cameraButton
                }
            }
        }
        // 띠 위를 누르면 띠 버튼만 반응하고, 그 밖의 사진·링을 누르면 링이 다시 돈다.
        .contentShape(Circle())
        .onTapGesture { replayTrigger += 1 }
    }

    @ViewBuilder
    private var imageContent: some View {
        if isDeleting {
            // 삭제 진행 중 — 헤더를 즉시 기본 상태로 전환
            defaultProfileIcon
        } else {
            ZStack {
                remoteImageOrDefault
                if let data = pendingImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            }
        }
    }

    @ViewBuilder
    private var remoteImageOrDefault: some View {
        if let profileImageUrl = profileImageUrl,
           let url = URL(string: profileImageUrl),
           url.scheme == "https" || url.scheme == "http" {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            loadedPhotoURL = url
                            onRemoteImageDisplayed(profileImageUrl)
                        }
                case .empty, .failure:
                    defaultProfileIcon
                @unknown default:
                    defaultProfileIcon
                }
            }
            // URL이 바뀌면 새로 그려 새 사진이 보일 때 다시 알린다
            .id(url)
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

    /// 사진이 실제로 그려졌는지(서버 사진을 다 불러왔거나 방금 고른 사진이 있음).
    /// 아니면(불러오는 중·실패·기본 아이콘) 띠를 반투명 검정 대신 옅은 회색 면으로 깔아, 흰 바탕 위에서 탁해 보이지 않게 한다.
    private var hasPhoto: Bool {
        if isDeleting { return false }
        if pendingImageData != nil { return true }
        guard let profileImageUrl, let url = URL(string: profileImageUrl) else { return false }
        return loadedPhotoURL == url
    }

    // 사진 아래 26 높이를 띠로 덮고 카메라를 얹는다(사진 원 밖으로 나가지 않아 떠 보이지 않는다, #340).
    // 누르는 칸은 띠를 포함한 아래 44 전체. 사진을 올리거나 지우는 중엔 사진과 같이 흐리게 두고 누를 수 없다.
    private var cameraButton: some View {
        Button(action: onCameraTapped) {
            Assets.MyProfile.Icon.camera.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(hasPhoto ? Color.semantic.icon.onOverlay : Color.semantic.icon.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(hasPhoto ? Color.semantic.overlay.scrim : Color.semantic.surface.tertiary)
                .frame(height: 44, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isBusy)
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
            // 닉네임 텍스트도 수정 진입 영역(정책 2.1, #66). 뱃지·글자·연필 사이 빈틈을 누르면 바탕(배경 고르기)이 받지 않게 한 버튼으로 묶는다.
            Button(action: onEditTapped) {
                HStack(spacing: 0) {
                    if isOwner {
                        Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 5)
                    }
                    Text(nickname)
                        .font(Font.pretendard.title3)
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                    EditPencil(foreground: foreground)
                }
                .editRowHitArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(nickname), 닉네임 수정")
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
        // 도장 이름 글자도 수정 진입 영역 — 연필만 버튼이면 글자를 누를 때 바탕(배경 고르기)이 열렸다.
        Button(action: onEditTapped) {
            HStack(spacing: 0) {
                Text(academyName)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(foreground.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                EditPencil(foreground: foreground)
            }
            .editRowHitArea()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(academyName), 도장 정보 수정")
        .frame(height: height)
        .padding(.horizontal, 20)
    }
}

// MARK: - 수정 행 공통

/// 닉네임·도장 이름 옆 연필 — 이름 글자보다 눈에 덜 띄게 둔 보조 표시
private struct EditPencil: View {
    let foreground: Color

    var body: some View {
        Assets.Common.Icon.pencil.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(foreground.opacity(0.35))
            .frame(width: 32, height: 32)
    }
}

private extension View {
    /// 보이는 자리는 그대로 두고 누르는 자리를 왼쪽으로 8pt 넓힌다. 높이는 연필 칸(32pt)이 이미 채운다 —
    /// 위아래로 넓히면 닉네임·도장 두 줄의 누르는 자리가 겹쳐 아래 줄이 위 줄 글자 아래쪽을 가로챈다.
    func editRowHitArea() -> some View {
        padding(.leading, 8)
            .contentShape(Rectangle())
            .padding(.leading, -8)
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
        onInstructorVerificationTapped: { },
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
        onInstructorVerificationTapped: { },
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
        onInstructorVerificationTapped: { },
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
                    onInstructorVerificationTapped: { },
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
