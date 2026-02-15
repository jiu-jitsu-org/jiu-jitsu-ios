//
//  MyProfileView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture
import Domain

extension Color {
}

private enum Style {
    enum Header {
        static let topPadding: CGFloat = 68 // Safe Area Top 부터 프로필 이미지까지의 거리
        static let bottomPaddingWithButton: CGFloat = 82.49
        static let bottomPaddingWithAcademyName: CGFloat = 99
    }
    
    enum Card {
        static let overlapHeightWithButton: CGFloat = 46.49     // 버튼이 있을 때 (도장 정보 없음)
        static let overlapHeightWithAcademyName: CGFloat = 71   // 도장 이름이 있을 때
        static let minHeight: CGFloat = 128        // 카드 최소 높이
    }
    
    struct DecorativeCardConfiguration {
        let image: Image
        let width: CGFloat
        let height: CGFloat
        let xPosition: CGFloat  // ZStack 중앙으로부터 카드 leading edge까지의 거리 (+ 오른쪽, - 왼쪽)
        let yPosition: CGFloat  // 상단으로부터의 거리
        let rotationDegrees: Double  // 회전 각도
        let zIndex: Double
        
        static let guardPosition = DecorativeCardConfiguration(
            image: Assets.MyProfile.Card.styleGuardPosition.swiftUIImage,
            width: 151.09,
            height: 117.58,
            xPosition: -2.49,
            yPosition: 26,
            rotationDegrees: 16.33,
            zIndex: 3
        )
        
        static let topPosition = DecorativeCardConfiguration(
            image: Assets.MyProfile.Card.styleTopPosition.swiftUIImage,
            width: 142,
            height: 110.51,
            xPosition: -152.36,
            yPosition: 59,
            rotationDegrees: -16.18,
            zIndex: 0
        )
        
        static let armLock = DecorativeCardConfiguration(
            image: Assets.MyProfile.Card.styleArmLock.swiftUIImage,
            width: 153.67,
            height: 119.6,
            xPosition: -33.49,
            yPosition: 110,
            rotationDegrees: -11.04,
            zIndex: 2
        )
        
        static let escapeDefense = DecorativeCardConfiguration(
            image: Assets.MyProfile.Card.styleEscapeDefense.swiftUIImage,
            width: 132.43,
            height: 103.09,
            xPosition: -109.64,
            yPosition: 163.46,
            rotationDegrees: 5.83,
            zIndex: 1
        )
    }
}

public struct MyProfileView: View {
    @Bindable var store: StoreOf<MyProfileFeature>
    
    public init(store: StoreOf<MyProfileFeature>) {
        self.store = store
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            // 도장 이름 유무에 따라 동적으로 overlap 높이 결정
            let cardOverlapHeight = store.communityProfile?.academyName != nil 
                ? Style.Card.overlapHeightWithAcademyName 
                : Style.Card.overlapHeightWithButton
            
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .bottom) {
                    // 메인 콘텐츠
                    VStack(spacing: 0) {
                        // 1. 헤더 영역
                        profileHeaderView(safeAreaTop: safeAreaTop)
                            .zIndex(0) // 배경
                        
                        // 2. 카드 영역 (Offset으로 겹침 효과 구현)
                        beltWeightCardView
                            .offset(y: -cardOverlapHeight) // 위로 끌어올림
                            .padding(.bottom, -cardOverlapHeight) // 끌어올린 만큼 공간 제거
                            .zIndex(1) // 헤더 위에 표시
                        
                        // 3. 스타일 영역
                        styleSectionView
                            .padding(.top, 72) // 카드와의 간격
                            .padding(.bottom, 18)
                    }
                    
                    // 배경 그라데이션 (최하위 레이어)
                    VStack {
                        Spacer()
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: "0090FF").opacity(0), location: 0),
                                .init(color: Color(hex: "0090FF").opacity(0.4), location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 433)
                    }
                    .offset(y: 58 + safeAreaBottom) // bottom 기준으로 위로 올림
                    .allowsHitTesting(false) // 터치 이벤트가 뒤의 콘텐츠로 전달되도록
                    .zIndex(-1)
                }
            }
            .scrollDisabled(false)
            .onAppear {
                UIScrollView.appearance().bounces = false
                store.send(.view(.onAppear))
            }
            .background(Color.component.background.default)
            .ignoresSafeArea(edges: .top)
            // 네비게이션 목적지 처리
            .navigationDestination(
                item: $store.scope(state: \.destination?.academySetting, action: \.destination.academySetting)
            ) { academySettingStore in
                MyAcademySettingView(store: academySettingStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.nicknameSetting, action: \.destination.nicknameSetting)
            ) { nicknameSettingStore in
                NicknameSettingView(store: nicknameSettingStore)
            }
            // 토스트 메시지 표시
            .overlay(alignment: .bottom) {
                if let toastState = store.toast {
                    ToastView(
                        state: toastState,
                        onSwipe: { store.send(.internal(.toastDismissed), animation: .default) },
                        onButtonTapped: { store.send(.view(.toastButtonTapped($0)), animation: .default) }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, toastState.bottomPadding)
                }
            }
            .animation(.default, value: store.toast)
            // 시트 처리
            .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { store in
                switch store.case {
                case let .beltSetting(beltSettingStore):
                    BeltSettingView(store: beltSettingStore)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .presentationDragIndicator(.hidden)
                        .presentationDetents([.height(336)])
                        .presentationBackground(
                            Color.component.bottomSheet.selected.container.background
                        )
                        
                case let .weightClassSetting(weightClassSettingStore):
                    WeightClassSettingView(store: weightClassSettingStore)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .presentationDragIndicator(.hidden)
                        .presentationDetents([.height(340)])
                        .presentationBackground(
                            Color.component.bottomSheet.selected.container.background
                        )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func profileHeaderView(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Color.component.myProfileHeader.bg.default
            
            VStack(spacing: 0) {
                // 상단 여백 (Safe Area + 지정된 여백)
                Spacer().frame(height: safeAreaTop + Style.Header.topPadding)
                
                // 프로필 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.component.list.setting.background)
                        .frame(width: 90, height: 90)
                    
                    if let profileImageUrl = store.communityProfile?.profileImageUrl,
                       let url = URL(string: profileImageUrl) {
                        // 실제 프로필 이미지가 있는 경우
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                            case .failure, .empty:
                                // 로딩 실패 시 기본 아이콘 표시
                                Assets.Common.Icon.profile.swiftUIImage
                                    .resizable()
                                    .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
                                    .frame(width: 64, height: 64)
                            @unknown default:
                                Assets.Common.Icon.profile.swiftUIImage
                                    .resizable()
                                    .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
                                    .frame(width: 64, height: 64)
                            }
                        }
                    } else {
                        // 프로필 이미지가 없는 경우 기본 아이콘 표시
                        Assets.Common.Icon.profile.swiftUIImage
                            .resizable()
                            .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
                            .frame(width: 64, height: 64)
                    }
                }
                
                // 닉네임
                HStack(spacing: 4) {
                    Text(store.communityProfile?.nickname ?? store.authInfo.userInfo?.nickname ?? "")
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.list.setting.background)
                    
                    // 수정 버튼
                    Button(action: { store.send(.view(.nicknameEditButtonTapped)) }) {
                        ZStack {
                            Assets.Common.Icon.pencil.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color(hex: "#FFFFFF").opacity(0.5))
                        }
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                
                // 도장 이름 표시 (있는 경우)
                if let academyName = store.communityProfile?.academyName {
                    HStack(spacing: 0) {
                        Text(academyName)
                            .font(Font.pretendard.bodyS)
                            .foregroundStyle(Color.component.list.setting.background.opacity(0.7))
                        
                        // 수정 버튼
                        Button(action: { store.send(.view(.gymInfoButtonTapped)) }) {
                            ZStack {
                                Assets.Common.Icon.pencil.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(Color(hex: "#FFFFFF").opacity(0.5))
                            }
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 7.5)
                    
                    Spacer().frame(height: Style.Header.bottomPaddingWithAcademyName)
                }
                
                // 버튼 - 도장 정보 유무에 따라 다른 버튼 표시
                if store.communityProfile?.academyName == nil {
                    Button {
                        store.send(.view(.gymInfoButtonTapped))
                    } label: {
                        AppButtonConfiguration(title: "도장 정보 입력하기", size: .small)
                    }
                    .appButtonStyle(.tint, size: .small)
                    .frame(height: 32)
                    .padding(.top, 15)
                    
                    // 헤더 내용물 아래의 여백 (이 공간 위로 카드가 겹쳐짐)
                    Spacer().frame(height: Style.Header.bottomPaddingWithButton)
                }
            }
        }
    }
    
    private var beltWeightCardView: some View {
        let profile = store.communityProfile
        let hasBeltInfo = profile?.beltRank != nil
        let hasWeightInfo = profile?.weightKg != nil
        
        return VStack(spacing: 24) {
            if hasBeltInfo && hasWeightInfo {
                // 정보가 있을 때: 좌우 레이아웃
                HStack(spacing: 0) {
                    // 왼쪽: 벨트 섹션
                    VStack(alignment: .center, spacing: 8) {
                        Text("벨트")
                            .font(Font.pretendard.labelM)
                            .foregroundStyle(Color.component.beltCard.filled.labelText)
                            .frame(height: 14)
                        
                        if let beltRank = profile?.beltRank {
                            // 벨트 아이콘
                            beltIcon(for: beltRank)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .background(Color.component.list.setting.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            if let beltStripe = profile?.beltStripe {
                                HStack(spacing: 5) {
                                    Text(beltRank.displayName)
                                        .font(Font.pretendard.bodyS)
                                        .foregroundStyle(Color.component.beltCard.filled.contentText)
                                    
                                    Text(beltStripe.displayName)
                                        .font(Font.pretendard.bodyS)
                                        .foregroundStyle(Color.component.beltCard.filled.contentText)
                                }
                                .frame(height: 17)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 중앙: 구분선
                    Rectangle()
                        .fill(Color.primitive.coolGray.cg75)
                        .frame(width: 1, height: 36)
                        .padding(.vertical, 24)
                    
                    // 오른쪽: 체급 섹션
                    VStack(spacing: 8) {
                        Text("체급")
                            .font(Font.pretendard.labelM)
                            .foregroundStyle(Color.component.beltCard.filled.labelText)
                            .frame(height: 14)
                        
                        if let weightKg = profile?.weightKg {
                            if profile?.isWeightHidden == true {
                                // 체급 숨김 상태
                                VStack(spacing: 4) {
                                    Text("숨김")
                                        .font(Font.pretendard.custom(weight: .medium, size: 24))
                                        .foregroundStyle(Color.component.beltCard.filled.contentText)
                                        .frame(height: 40)
                                    
                                    Button {
                                        store.send(.view(.weightVisibilityToggleButtonTapped))
                                    } label: {
                                        Text("보기")
                                            .font(Font.pretendard.buttonS)
                                            .foregroundStyle(Color.component.button.neutral.defaultText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.component.button.neutral.defaultBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .frame(height: 22)
                                }
                            } else {
                                // 체급 표시 상태
                                VStack(spacing: 4) {
                                    Text(String(format: "%.1fkg", weightKg))
                                        .font(Font.pretendard.custom(weight: .medium, size: 24))
                                        .foregroundStyle(Color.component.beltCard.filled.contentText)
                                        .frame(height: 40)
                                    
                                    Button {
                                        store.send(.view(.weightVisibilityToggleButtonTapped))
                                    } label: {
                                        Text("숨기기")
                                            .font(Font.pretendard.buttonS)
                                            .foregroundStyle(Color.component.button.neutral.defaultText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.component.button.neutral.defaultBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .frame(height: 22)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            } else {
                // 정보가 없을 때: 기존 UI
                VStack(spacing: 8) {
                    HStack(spacing: 5) {
                        // 왼쪽 (벨트)
                        VStack {
                            Assets.MyProfile.Icon.beltBlue.swiftUIImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 13)
                        .rotationEffect(.degrees(-6.8))
                        
                        // 오른쪽 (체급)
                        VStack {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("??")
                                    .font(Font.pretendard.title2)
                                    .foregroundStyle(Color.primitive.coolGray.cg700)
                                
                                Text("kg")
                                    .font(Font.pretendard.bodyS)
                                    .foregroundStyle(Color.primitive.coolGray.cg400)
                            }
                        }
                        .frame(width: 55, height: 42)
                        .background(Color.primitive.coolGray.cg25)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 5)
                        .rotationEffect(.degrees(10.49))
                    }
                    .frame(height: 56)
                    
                    Text("벨트와 체급이 어떻게 되세요?")
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.beltCard.default.text)
                }
                .padding(.top, 24)
                
                Button {
                    store.send(.view(.registerBeltButtonTapped))
                } label: {
                    AppButtonConfiguration(title: "벨트/체급 등록하기", size: .medium)
                }
                .appButtonStyle(.primary, size: .medium)
                .frame(height: 38)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Style.Card.minHeight)
        .background(Color.component.beltCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    // 벨트 등급에 따른 아이콘 반환
    private func beltIcon(for beltRank: BeltRank) -> Image {
        switch beltRank {
        case .white:
            return Assets.MyProfile.Icon.beltWhite.swiftUIImage
        case .blue:
            return Assets.MyProfile.Icon.beltBlue.swiftUIImage
        case .purple:
            return Assets.MyProfile.Icon.beltPurple.swiftUIImage
        case .brown:
            return Assets.MyProfile.Icon.beltBrown.swiftUIImage
        case .black:
            return Assets.MyProfile.Icon.beltBlack.swiftUIImage
        }
    }
    
    private var styleSectionView: some View {
        let profile = store.communityProfile
        let hasStyleInfo = profile?.bestSubmission != nil ||
                          profile?.favoritePosition != nil ||
                          profile?.bestTechnique != nil
        
        return VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("나의 주짓수를 보여주세요")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)
                
                if hasStyleInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        if let bestSubmission = profile?.bestSubmission {
                            HStack {
                                Text("최고 서브미션:")
                                    .font(Font.pretendard.bodyM)
                                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                                Text(bestSubmission.displayName)
                                    .font(Font.pretendard.bodyM.bold())
                                    .foregroundStyle(Color.component.sectionHeader.title)
                            }
                        }
                        
                        if let favoritePosition = profile?.favoritePosition {
                            HStack {
                                Text("선호 포지션:")
                                    .font(Font.pretendard.bodyM)
                                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                                Text(favoritePosition.displayName)
                                    .font(Font.pretendard.bodyM.bold())
                                    .foregroundStyle(Color.component.sectionHeader.title)
                            }
                        }
                        
                        if let bestTechnique = profile?.bestTechnique {
                            HStack {
                                Text("최고 기술:")
                                    .font(Font.pretendard.bodyM)
                                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                                Text(bestTechnique.displayName)
                                    .font(Font.pretendard.bodyM.bold())
                                    .foregroundStyle(Color.component.sectionHeader.title)
                            }
                        }
                    }
                    .padding(.top, 8)
                } else {
                    Text("특기와 최애 포지션, 기술 등을 등록해보세요.")
                        .font(Font.pretendard.bodyM)
                        .foregroundStyle(Color.component.sectionHeader.subTitle)
                }
            }
            
            if !hasStyleInfo {
                Button {
                    store.send(.view(.registerStyleButtonTapped))
                } label: {
                    AppButtonConfiguration(title: "내 스타일 등록하기", size: .medium)
                }
                .appButtonStyle(.tint, size: .medium)
                .frame(height: 38)
                .padding(.top, 24)
            }
            
            decorativeCardsView
                .padding(.top, 16)
        }
    }
    
    private var decorativeCardsView: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            
            ZStack(alignment: .top) {
                decorativeCard(config: .guardPosition, centerX: centerX)
                decorativeCard(config: .topPosition, centerX: centerX)
                decorativeCard(config: .armLock, centerX: centerX)
                decorativeCard(config: .escapeDefense, centerX: centerX)
            }
        }
        .frame(height: 282) // 카드들이 모두 들어갈 수 있는 높이 설정
    }
    
    private func decorativeCard(config: Style.DecorativeCardConfiguration, centerX: CGFloat) -> some View {
        config.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: config.width, height: config.height)
            .rotationEffect(.degrees(config.rotationDegrees))
            .position(
                x: centerX + config.xPosition + config.width / 2,  // ZStack 중앙 + xPosition(leading 기준) + 카드 너비의 절반
                y: config.yPosition + config.height / 2
            )
            .zIndex(config.zIndex)
    }
}

#Preview {
    MyProfileView(
        store: Store(
            initialState: MyProfileFeature.State(
                authInfo: AuthInfo(
                    accessToken: "sample_token",
                    refreshToken: "sample_refresh",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "user@example.com",
                        nickname: "주짓수 러버",
                        profileImageUrl: nil,
                        snsProvider: "apple",
                        deactivatedWithinGrace: false
                    )
                )
            )
        ) {
            MyProfileFeature()
        }
    )
}
