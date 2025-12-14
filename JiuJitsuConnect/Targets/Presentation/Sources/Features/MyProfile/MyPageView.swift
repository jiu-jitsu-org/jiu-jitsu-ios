//
//  MyPageView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture
import Domain

private enum Style {
    enum Header {
        static let topPadding: CGFloat = 68 // Safe Area Top 부터 프로필 이미지까지의 거리
        static let bottomPadding: CGFloat = 82
    }
    
    enum Card {
        static let overlapHeight: CGFloat = 46     // 카드가 헤더와 겹치는 높이
        static let minHeight: CGFloat = 195        // 카드 최소 높이
    }
}

public struct MyPageView: View {
    let store: StoreOf<MyPageFeature>
    
    public init(store: StoreOf<MyPageFeature>) {
        self.store = store
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            
            ScrollView {
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
                        .padding(.top, 30) // 카드와의 간격
                        .padding(.bottom, 50)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.component.background.default)
            .ignoresSafeArea(edges: .top)
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
        .padding(.horizontal, 20)
    }
    
    private var styleSectionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("나의 주짓수를 보여주세요")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text("특기와 최애 포지션, 기술 등을 등록해보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Button {
                store.send(.registerStyleButtonTapped)
            } label: {
                Text("내 스타일 등록하기")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
            }
            
            decorativeCardsView
                .padding(.top, 20)
        }
    }
    
    private var decorativeCardsView: some View {
        ZStack {
            HStack(spacing: -15) {
                decorativeCard(icon: "figure.wrestling", title: "특기", subtitle: "탑 포지션", color: .red)
                    .rotationEffect(.degrees(-16.18))
                    .offset(y: 20)
                
                VStack(spacing: -10) {
                    decorativeCard(icon: "figure.strengthtraining.traditional", title: "최애", subtitle: "가드 포지션", color: .gray)
                        .rotationEffect(.degrees(5))
                        .zIndex(1)
                    
                    decorativeCard(icon: "figure.rolling", title: "특기", subtitle: "팔 관절기", color: .cyan)
                        .rotationEffect(.degrees(-5))
                }
                
                decorativeCard(icon: "figure.run", title: "특기", subtitle: "이스케이프", color: .green)
                    .rotationEffect(.degrees(10))
                    .offset(y: 30)
            }
        }
    }
    
    private func decorativeCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Font.pretendard.custom(weight: .medium, size: 10))
                    .foregroundStyle(Color.component.skillCard.default.labelText)
                Text(subtitle)
                    .font(Font.pretendard.custom(weight: .semiBold, size: 16))
                    .foregroundStyle(Color.component.skillCard.default.titleTextFilled)
            }
        }
        .padding(14)
        .frame(width: 142, height: 111, alignment: .topLeading)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(
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
            MyPageFeature()
        }
    )
}
