import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    
    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // MARK: - 브랜드 영역
                    brandSection

                    Spacer()

                    // MARK: - 소셜 로그인 버튼
                    VStack(spacing: 10) {
                        // 카카오 로그인 버튼
                        Button(action: { store.send(.view(.kakaoButtonTapped)) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.kakao,
                                text: "카카오 계속하기",
                                backgroundColor: Color.primitive.kakao.bg,
                                foregroundColor: Color.primitive.kakao.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 구글 로그인 버튼
                        Button(action: { store.send(.view(.googleButtonTapped)) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.google,
                                text: "구글로 계속하기",
                                backgroundColor: Color.primitive.google.bg,
                                foregroundColor: Color.primitive.google.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 애플 로그인 버튼
                        Button(action: { store.send(.view(.appleButtonTapped)) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.apple,
                                text: "애플로 계속하기",
                                backgroundColor: Color.primitive.apple.bg,
                                foregroundColor: Color.primitive.apple.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 둘러보기 버튼
                        Button(action: { store.send(.view(.aroundButtonTapped)) }) {
                            Text("로그인 없이 둘러보기")
                                .font(Font.pretendard.custom(weight: .medium, size: 14))
                                .foregroundStyle(Color.primitive.coolGray.cg200)
                                .underline(true, color: Color.primitive.coolGray.cg300)
                        }
                        .frame(height: 44)
                    }
                    .padding(.horizontal, 35)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } destination: { store in
            switch store.case {
            case let .nicknameSetting(nicknameStore):
                NicknameSettingView(store: nicknameStore)
            case let .signupComplete(signupCompleteStore):
                SignupCompleteView(store: signupCompleteStore)
            }
        }
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
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { store in
            // CaseLet을 바로 사용하지 않고, destinationStore의 상태로 switch합니다.
            switch store.case {
            case let .termsAgreement(termsStore):
                TermsAgreementView(store: termsStore)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents(
                        [.height(calculateSheetHeight(itemCount: termsStore.state.rows.count))]
                    )
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
            }
        }
        //        }
    }
    
    // MARK: - 브랜드 영역

    private var brandSection: some View {
        VStack(spacing: 20) {
            // 워드마크 엠블럼
            Circle()
                .fill(Color.primitive.bw.white)
                .frame(width: 96, height: 96)
                .overlay {
                    Text("OSS")
                        .font(Font.cookieRun.custom(weight: .black, size: 30))
                        .foregroundStyle(Color.primitive.coolGray.cg900)
                }
                .shadow(color: Color.primitive.opacity.black40, radius: 16, y: 8)

            VStack(spacing: 8) {
                Text("주짓떼로/주짓떼라를 위한 커뮤니티")
                    .font(Font.pretendard.title2)
                    .foregroundStyle(Color.primitive.bw.white)

                Text("매트 위의 경험을 나누고 함께 성장해요")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.primitive.coolGray.cg200)
            }
        }
    }

    // MARK: - 배경

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.primitive.coolGray.cg700, Color.primitive.coolGray.cg500],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func calculateSheetHeight(itemCount: Int) -> CGFloat {
        // 기본 UI 높이 (핸들, 타이틀, 버튼, 여백 등)
        let baseHeight: CGFloat = 24 + 48 + 16 + 16 + 8 + 52 + 8
        // 각 약관 항목 Row의 높이
        let rowHeight: CGFloat = 40
        // 항목 사이의 간격
        let spacing: CGFloat = 4
        // 최종 높이 계산
        let totalHeight = baseHeight + (CGFloat(itemCount) * rowHeight) + (CGFloat(max(0, itemCount - 1)) * spacing)
        return totalHeight
    }
}

// MARK: - 재사용 가능한 소셜 로그인 버튼 View
struct SocialLoginButton: View {
    let asset: ImageAsset
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    var borderColor: Color = .clear // 테두리 색상 (선택 사항)
    
    var body: some View {
        HStack(spacing: 21) {
            asset.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
            
            Text(text)
                .font(Font.pretendard.custom(weight: .medium, size: 16))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.primitive.opacity.black40, radius: 8, y: 4)
    }
}

#Preview("Login View") {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
            // _printChanges()를 붙이면 Preview에서 버튼을 눌렀을 때
            // 어떤 Action이 발생하는지 콘솔에서 확인할 수 있어 유용합니다.
                ._printChanges()
        }
    )
}
