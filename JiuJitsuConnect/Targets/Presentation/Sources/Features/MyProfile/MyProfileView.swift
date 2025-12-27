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
        static let bottomPadding: CGFloat = 82.49
    }
    
    enum Card {
        static let overlapHeight: CGFloat = 46     // 카드가 헤더와 겹치는 높이
        static let minHeight: CGFloat = 195        // 카드 최소 높이
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
    @Bindable var store: StoreOf<MyPrpfileFeature>
    
    public init(store: StoreOf<MyPrpfileFeature>) {
        self.store = store
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .bottom) {
                    // 메인 콘텐츠
                    VStack(spacing: 0) {
                        // 1. 헤더 영역
                        profileHeaderView(safeAreaTop: safeAreaTop)
                            .zIndex(0) // 배경
                        
                        // 2. 카드 영역 (Offset으로 겹침 효과 구현)
                        beltWeightCardView
                            .offset(y: -Style.Card.overlapHeight) // 위로 끌어올림
                            .padding(.bottom, -Style.Card.overlapHeight) // 끌어올린 만큼 공간 제거
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
            }
            .background(Color.component.background.default)
            .ignoresSafeArea(edges: .top)
            // 네비게이션 목적지 처리
            .navigationDestination(
                item: $store.scope(state: \.destination?.academySetting, action: \.destination.academySetting)
            ) { academySettingStore in
                MyAcademySettingView(store: academySettingStore)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func profileHeaderView(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Color.component.myProfileHeader.bg.default
            
            VStack(spacing: 8) {
                // 상단 여백 (Safe Area + 지정된 여백)
                Spacer().frame(height: safeAreaTop + Style.Header.topPadding)
                
                // 프로필 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.component.list.setting.background)
                        .frame(width: 90, height: 90)
                    
                    Assets.Common.Icon.profile.swiftUIImage
                        .resizable()
                        .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
                        .frame(width: 64, height: 64)
                }
                
                // 닉네임
                Text(store.authInfo.userInfo?.nickname ?? "")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.list.setting.background)
                    .frame(height: 24)
                
                // 버튼
                Button {
                    store.send(.gymInfoButtonTapped)
                } label: {
                    AppButtonConfiguration(title: "도장 정보 입력하기", size: .small)
                }
                .appButtonStyle(.tint, size: .small)
                .frame(height: 32)
                .padding(.top, 7)
                
                // 헤더 내용물 아래의 여백 (이 공간 위로 카드가 겹쳐짐)
                Spacer().frame(height: Style.Header.bottomPadding)
            }
        }
    }
    
    private var beltWeightCardView: some View {
        VStack(spacing: 24) {
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
            
            Button {
                store.send(.registerBeltButtonTapped)
            } label: {
                AppButtonConfiguration(title: "벨트/체급 등록하기", size: .medium)
            }
            .appButtonStyle(.primary, size: .medium)
            .frame(height: 38)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: Style.Card.minHeight)
        .background(Color.component.beltCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    private var styleSectionView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("나의 주짓수를 보여주세요")
                    .font(Font.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)
                
                Text("특기와 최애 포지션, 기술 등을 등록해보세요.")
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
            }
            
            Button {
                store.send(.gymInfoButtonTapped)
            } label: {
                AppButtonConfiguration(title: "내 스타일 등록하기", size: .medium)
            }
            .appButtonStyle(.tint, size: .medium)
            .frame(height: 38)
            .padding(.top, 24)
            
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
            initialState: MyPrpfileFeature.State(
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
            MyPrpfileFeature()
        }
    )
}
