//
//  SignupCompleteView.swift
//  Presentation
//
//  Created by suni on 11/22/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct SignupCompleteView: View {
    @Bindable var store: StoreOf<SignupCompleteFeature>
    
    public init(store: StoreOf<SignupCompleteFeature>) {
        self.store = store
    }
    
    public var body: some View {
        // 전체를 감싸는 ZStack
        ZStack(alignment: .top) {
            
            // MARK: - Layer 1: 배경 Lottie (고정)
            VStack(spacing: 0) {
                Color.clear
                    .frame(width: 160, height: 160)
                    .overlay(alignment: .center) {
                        JJSLottieView("Confetti", loopMode: .loop)
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                    }
                    .padding(.top, 169)
                
                Spacer()
            }
            .zIndex(0)
            
            // MARK: - Layer 2: 움직이는 중앙 컨텐츠 (애니메이션 적용 대상)
            VStack(spacing: 0) {
                // 1. 체크 아이콘
                Assets.Signup.Icon.signupComplete.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .padding(.top, 169)
                
                // 2. 텍스트 그룹
                VStack(spacing: 8) {
                    Text("환영해요!")
                        .font(.pretendard.display1)
                        .foregroundStyle(Color.component.cta.primary.bg)
                    
                    Text("\(store.authInfo.userInfo?.nickname ?? "사용자")님!")
                        .font(.pretendard.display1)
                        .foregroundStyle(Color.component.textfieldDisplay.default.title)
                }
                .padding(.top, 116)
                
                // 공간 채우기 (버튼 자리 침범 방지용이나 레이아웃 유지를 위해)
                Spacer()
            }
            .zIndex(1)
            // ✨ 애니메이션 효과
            .opacity(store.isContentVisible ? 1 : 0)
            .offset(y: store.isContentVisible ? 0 : 40)
            
            // MARK: - Layer 3: 하단 버튼 (고정, 애니메이션 없음)
            VStack {
                Spacer() // 버튼을 바닥으로 밀어냄
                ctaButton
            }
            .zIndex(2) // 맨 위에 위치 (터치 보장)
        }
        .onAppear {
            store.send(.onAppear)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// MARK: - Private Views
private extension SignupCompleteView {
    
    // 하단 CTA 버튼
    var ctaButton: some View {
        CTAButton(
            title: "홈으로",
            action: {
                store.send(.homeButtonTapped)
            }
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview
import Domain

#Preview {
    // 1. 테스트에 필요한 Mock 데이터를 생성합니다.
    // 이 AuthInfo는 실제 서버에서 온 것이 아니라, 순전히 Preview를 위한 가짜 데이터입니다.
    let mockAuthInfo = AuthInfo(
        accessToken: "fake-access-token",
        refreshToken: "fake-refresh-token",
        tempToken: nil,
        isNewUser: true,
        userInfo: .init(
            userId: 123,
            email: "test@example.com",
            nickname: "부리부리 대마왕", // UI에 표시될 닉네임
            profileImageUrl: nil,
            snsProvider: "KAKAO",
            deactivatedWithinGrace: false
        )
    )
    
    // 2. NavigationStack으로 감싸서 실제 앱 환경과 유사하게 만듭니다.
    return NavigationStack {
        SignupCompleteView(
            store: Store(
                // 3. Mock 데이터로 Feature의 초기 상태를 만듭니다.
                initialState: SignupCompleteFeature.State(authInfo: mockAuthInfo),
                reducer: {
                    SignupCompleteFeature()
                        // _printChanges()를 사용하면 Preview에서 버튼을 눌렀을 때
                        // 어떤 Action이 발생하는지 콘솔에서 확인할 수 있습니다.
                        ._printChanges()
                }
            )
        )
    }
}
