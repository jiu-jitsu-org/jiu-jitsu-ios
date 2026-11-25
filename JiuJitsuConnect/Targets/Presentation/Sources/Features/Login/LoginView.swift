import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

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
        .toast(
            store.toast,
            onSwipe: { store.send(.internal(.toastDismissed)) },
            onButtonTapped: { store.send(.view(.toastButtonTapped($0))) }
        )
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { store in
            // CaseLet을 바로 사용하지 않고, destinationStore의 상태로 switch합니다.
            switch store.case {
            case let .termsAgreement(termsStore):
                TermsAgreementView(store: termsStore)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents(
                        [.height(calculateSheetHeight(
                            itemCount: termsStore.state.rows.count,
                            hasRecentLoginNotice: termsStore.state.recentOtherProvider != nil
                        ))]
                    )
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
            }
        }
        // 파란 화면이 보일 때만 상태 막대를 흰색으로. 닉네임 설정·약관 시트가 뜨면 원래대로 돌아간다
        .lightStatusBar(store.path.isEmpty && store.sheet == nil)
        .onAppear { store.send(.view(.onAppear)) }
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
        .disabled(store.isLoading)
    }
    #endif

    // MARK: - 소셜 로그인 버튼

    private var loginButtons: some View {
        VStack(spacing: 10) {
            Button(action: { store.send(.view(.kakaoButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.kakao,
                    isLoading: store.loadingProvider == .kakao,
                    isRecent: store.lastLoginProvider == .kakao,
                    text: "카카오로 계속하기",
                    backgroundColor: Color.primitive.kakao.bg,
                    foregroundColor: Color.primitive.kakao.text
                )
            }
            .loginButtonDimmed(store.isLoading && store.loadingProvider != .kakao)

            // 흰 시트 위의 흰 버튼이라 테두리로 경계를 잡는다
            Button(action: { store.send(.view(.googleButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.google,
                    isLoading: store.loadingProvider == .google,
                    isRecent: store.lastLoginProvider == .google,
                    text: "Google로 계속하기",
                    backgroundColor: Color.primitive.google.bg,
                    foregroundColor: Color.primitive.google.text,
                    borderColor: Color.primitive.coolGray.cg75
                )
            }
            .loginButtonDimmed(store.isLoading && store.loadingProvider != .google)

            Button(action: { store.send(.view(.appleButtonTapped)) }) {
                SocialLoginButton(
                    asset: Assets.Login.Logo.apple,
                    isLoading: store.loadingProvider == .apple,
                    isRecent: store.lastLoginProvider == .apple,
                    text: "Apple로 계속하기",
                    backgroundColor: Color.primitive.apple.bg,
                    foregroundColor: Color.primitive.apple.text
                )
            }
            .loginButtonDimmed(store.isLoading && store.loadingProvider != .apple)

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
            .loginButtonDimmed(store.isLoading)
        }
        // 누른 버튼은 스피너를 돌리며 그대로 두되 다시 눌리지는 않게 막는다
        .disabled(store.isLoading)
        .animation(.easeInOut(duration: 0.15), value: store.loadingProvider)
    }

    private func calculateSheetHeight(itemCount: Int, hasRecentLoginNotice: Bool) -> CGFloat {
        // 기본 UI 높이 (핸들, 타이틀, 버튼, 여백 등)
        let noticeHeight = hasRecentLoginNotice ? TermsAgreementView.recentLoginNoticeBlockHeight : 0
        let baseHeight: CGFloat = 24 + 48 + noticeHeight + 16 + 16 + 8 + 52 + 8
        // 각 약관 항목 Row의 높이
        let rowHeight: CGFloat = 40
        // 항목 사이의 간격
        let spacing: CGFloat = 4
        // 최종 높이 계산
        let totalHeight = baseHeight + (CGFloat(itemCount) * rowHeight) + (CGFloat(max(0, itemCount - 1)) * spacing)
        return totalHeight
    }
}

// MARK: - 서버 로그인 진행 표시 (#384)

private extension View {
    /// 서버 확인을 기다리는 동안 누르지 않은 버튼을 흐리게 해, 지금 어느 계정으로 로그인 중인지 보이게 한다.
    /// 표시가 없으면 사람들은 멈춘 줄 알고 버튼을 다시 누르는데, 진행 중엔 리듀서가 그 탭을 버려 아무 반응이 없다.
    func loginButtonDimmed(_ isDimmed: Bool) -> some View {
        opacity(isDimmed ? 0.35 : 1)
    }
}

// MARK: - 재사용 가능한 소셜 로그인 버튼 View
struct SocialLoginButton: View {
    let asset: ImageAsset
    /// 서버 로그인 중 — 로고 자리에 스피너를 돌린다. 문구는 그대로 둬 버튼 폭이 들썩이지 않는다.
    var isLoading = false
    /// 이 기기에서 마지막으로 로그인한 수단(#380) — 오른쪽 위에 "최근 로그인"을 걸쳐 단다.
    var isRecent = false
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    var borderColor: Color = .clear // 테두리 색상 (선택 사항)

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foregroundColor)
                } else {
                    asset.swiftUIImage
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 22, height: 22)

            Text(text)
                .font(Font.pretendard.custom(weight: .medium, size: 16))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        // 버튼 위 간격(10)과 시트 위 여백(28)에 걸치게 올려, 버튼 줄의 높이와 문구 자리를 바꾸지 않는다
        .overlay(alignment: .topTrailing) {
            if isRecent {
                RecentLoginBadge()
                    .offset(x: -12, y: -11)
            }
        }
    }

    private var accessibilityValue: String {
        if isLoading { return "로그인하는 중" }
        return isRecent ? "최근 로그인" : ""
    }
}

// MARK: - 최근 로그인 표시 (#380)
/// 모양 · 자리는 디자인 확인 전 임시안이다. 흰 시트와 버튼 경계에 걸치므로 시트 색 테두리로 버튼에서 떼어 보이게 한다.
private struct RecentLoginBadge: View {
    var body: some View {
        Text("최근 로그인")
            .font(Font.pretendard.labelM)
            .foregroundStyle(Color.semantic.primary.onPrimary)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Color.semantic.primary.primary, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primitive.bw.trueWhite, lineWidth: 2))
            // 버튼의 accessibilityValue로 읽으므로 따로 읽지 않는다
            .accessibilityHidden(true)
    }
}

#Preview("Login View — 최근 로그인 카카오") {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.authClient.lastLoginProvider = { .kakao }
        }
    )
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
