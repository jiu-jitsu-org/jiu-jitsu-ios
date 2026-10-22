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
            LoginSceneView {
                loginButtons
            }
            // 빈 내비게이션 바가 안전 영역을 차지하지 않도록 첫 화면에서만 숨긴다
            .toolbar(.hidden, for: .navigationBar)
            #if BETA
            // Beta 스킴 전용 테스트 로그인. 기존 로그인 레이아웃을 건드리지 않도록
            // 본문 위에 떠 있는 오버레이로만 올린다.
            .overlay(alignment: .topTrailing) { testLoginButton }
            #endif
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
        // 파란 화면이 보일 때만 상태 막대를 흰색으로. 닉네임 설정·약관 시트가 뜨면 원래대로 돌아간다
        .lightStatusBar(store.path.isEmpty && store.sheet == nil)
    }
    
    #if BETA
    // MARK: - Beta 전용 테스트 로그인 버튼
    private var testLoginButton: some View {
        Button(action: { store.send(.view(.testLoginTapped)) }) {
            Text("테스트 로그인")
                .font(Font.pretendard.custom(weight: .medium, size: 13))
                .foregroundStyle(Color.primitive.bw.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primitive.coolGray.cg700.opacity(0.85), in: Capsule())
                .overlay(Capsule().stroke(Color.primitive.bw.white.opacity(0.4), lineWidth: 1))
        }
        .padding(.top, 8)
        .padding(.trailing, 16)
    }
    #endif

    // MARK: - 소셜 로그인 버튼

    private var loginButtons: some View {
        VStack(spacing: 10) {
            Button(action: { store.send(.view(.kakaoButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.kakao,
                    text: "카카오로 계속하기",
                    backgroundColor: Color.primitive.kakao.bg,
                    foregroundColor: Color.primitive.kakao.text
                )
            }

            // 흰 시트 위의 흰 버튼이라 테두리로 경계를 잡는다
            Button(action: { store.send(.view(.googleButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.google,
                    text: "구글로 계속하기",
                    backgroundColor: Color.primitive.google.bg,
                    foregroundColor: Color.primitive.google.text,
                    borderColor: Color.primitive.coolGray.cg75
                )
            }

            Button(action: { store.send(.view(.appleButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.apple,
                    text: "애플로 계속하기",
                    backgroundColor: Color.primitive.apple.bg,
                    foregroundColor: Color.primitive.apple.text
                )
            }

            Button(action: { store.send(.view(.aroundButtonTapped)) }) {
                Text("로그인 없이 둘러보기")
                    .font(Font.pretendard.custom(weight: .medium, size: 14))
                    .foregroundStyle(Color.primitive.coolGray.cg400)
                    .underline(true, color: Color.primitive.coolGray.cg100)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.top, 2)
        }
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
        HStack(spacing: 12) {
            asset.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(text)
                .font(Font.pretendard.custom(weight: .medium, size: 16))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
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
