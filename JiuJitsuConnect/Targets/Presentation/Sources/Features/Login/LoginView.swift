import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                VStack {
                    Spacer()
                    // MARK: - 소셜 로그인 버튼
                    VStack(spacing: 10) {
                        // 카카오 로그인 버튼
                        Button(action: { store.send(.kakaoButtonTapped) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.kakao,
                                text: "카카오 계속하기",
                                backgroundColor: Color.primitive.kakao.bg,
                                foregroundColor: Color.primitive.kakao.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 구글 로그인 버튼
                        Button(action: { store.send(.googleButtonTapped) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.google,
                                text: "구글로 계속하기",
                                backgroundColor: Color.primitive.google.bg,
                                foregroundColor: Color.primitive.google.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 애플 로그인 버튼
                        Button(action: { store.send(.appleButtonTapped) }) {
                            SocialLoginButton(
                                asset: Assets.Login.Logo.apple,
                                text: "애플로 계속하기",
                                backgroundColor: Color.primitive.apple.bg,
                                foregroundColor: Color.primitive.apple.text
                            )
                        }
                        .frame(height: 52)
                        
                        // 둘러보기 버튼
                        Button(action: { store.send(.aroundButtonTapped) }) {
                            Text("로그인 없이 둘러보기")
                                .font(Font.pretendard.custom(weight: .semiBold, size: 16))
                                .foregroundStyle(Color.primitive.bw.white)
                        }
                        .frame(height: 44)
                    }
                    .padding(.horizontal, 35)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primitive.coolGray.cg500)
            }
            .overlay {
                if let toastState = viewStore.toast {
                    ToastView(
                        state: toastState,
                        onSwipe: {
                            viewStore.send(.toastDismissed, animation: .default)
                        },
                        onButtonTapped: { toastAction in
                            viewStore.send(.toastButtonTapped(toastAction), animation: .default)
                        },
                        hasBottomNavBar: false
                    )
                }
            }
            .animation(.default, value: viewStore.toast)
        }
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
