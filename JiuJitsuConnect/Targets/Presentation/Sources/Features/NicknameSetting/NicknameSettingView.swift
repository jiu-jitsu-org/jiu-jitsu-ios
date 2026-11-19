import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct NicknameSettingView: View {

    @Bindable var store: StoreOf<NicknameSettingFeature>

    public init(store: StoreOf<NicknameSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 가입 중에도 뒤로가기를 둔다 — 없으면 닉네임을 정하거나 앱을 꺼야만 나갈 수 있다(#368).
            headerView
            titleSection
            textFieldSection
            Spacer()
            ctaButtonSection
        }
        .onAppear {
            store.send(.view(.onAppear))
        }
        .onTapGesture {
            store.send(.view(.viewTapped))
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .appAlert(
            isPresented: Binding(
                get: { store.isQuitSignupAlertPresented },
                set: { if !$0 { store.send(.view(.quitSignupAlertDismissed)) } }
            ),
            configuration: AppAlertConfiguration(
                title: "가입을 그만둘까요?",
                message: "지금 그만두면 처음부터 다시 가입해야 해요.",
                // 계속하기를 강조한다 — 그만두면 약관부터 다시 해야 한다.
                primaryButton: .init(title: "계속하기", style: .primary, action: { store.send(.view(.quitSignupAlertDismissed)) }),
                secondaryButton: .init(title: "그만두기", style: .neutral, action: { store.send(.view(.quitSignupConfirmed)) })
            )
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        // 가입 중엔 스와이프로 바로 나가지 않게 막고 뒤로가기와 같이 '그만둘까요?'를 묻는다(#368).
        // 바를 숨겨도 앱 전역 확장이 스와이프를 다시 켜 둔다(UINavigationController+SwipeBack). 수정 모드는 지금처럼 스와이프로 나간다.
        .background {
            if store.mode == .initial {
                InteractivePopBlocker(onBlocked: { store.send(.view(.backButtonTapped)) })
            }
        }
    }
}

// MARK: - Private Views
private extension NicknameSettingView {

    var headerView: some View {
        TopHeader(
            title: store.mode.headerTitle,
            onBack: { store.send(.view(.backButtonTapped)) }
        )
    }

    var titleSection: some View {
        Text(store.validationState.message(in: store.mode))
            .font(Font.pretendard.display1)
            .foregroundStyle(store.validationState.messageColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .lineSpacing(6.2)
            .padding(.horizontal, 30)
            .padding(.top, 120)
            .padding(.bottom, 8)
    }
    
    var textFieldSection: some View {
        ZStack {
            // 정책 1: 초기 상태에서 플레이스홀더를 보여줍니다.
            if !store.isTextFieldActive {
                Text("닉네임을 입력해주세요")
                    .font(Font.pretendard.display1)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
            } else if store.nickname.isEmpty {
                // 정책 3: 입력을 시작했지만 비어있으면 키보드 상태와 관계없이 커스텀 커서를 보여줍니다.
                // (가운데 정렬 TextField는 빈 상태에서 네이티브 커서가 보이지 않음)
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }
            
            // 표시와 입력을 하나의 줄바꿈 필드가 담당합니다.
            // 표시용 Text(줄바꿈)와 입력용 단일 라인 TextField(가로 스크롤)를 겹치면
            // 2줄 이상일 때 caret이 실제 텍스트 끝이 아닌 오른쪽 가운데에 고정되므로 분리하지 않습니다.
            // Return은 개행 없이 확인 버튼과 동일하게 처리합니다.
            MultilineTextField(
                text: $store.nickname,
                isFocused: $store.isKeyboardVisible,
                font: UIFont.pretendard.display1,
                textColor: store.validationState.textColor,
                // 정책 1: 초기 상태에서는 네이티브 커서를 숨깁니다.
                // 정책 2: 입력 시작 후에는 네이티브 커서를 보여줍니다.
                tintColor: store.isTextFieldActive ? Color.component.textfieldDisplay.focus.text : .clear,
                onSubmit: { store.send(.view(.doneButtonTapped)) }
            )
        }
        .padding(.horizontal, 30)
    }
    
    var ctaButtonSection: some View {
        CTAButton(
            title: store.mode.ctaTitle,
            type: .blue,
            style: .keypad,
            height: 56,
            action: {
                store.send(.view(.doneButtonTapped))
            }
        )
        .disabled(!store.isCtaButtonEnabled)
    }
}

// MARK: - Custom Cursor View
private struct BlinkingCursorView: View {
    @State private var isVisible: Bool = false
    
    var body: some View {
        Rectangle()
            .fill(Color.component.textfieldDisplay.focus.text)
            .frame(width: 2, height: 36)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isVisible.toggle()
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        NicknameSettingView(
            store: Store(initialState: NicknameSettingFeature.State(tempToken: "test-token", isMarketingAgreed: false)) {
                NicknameSettingFeature()
            }
        )
    }
}
