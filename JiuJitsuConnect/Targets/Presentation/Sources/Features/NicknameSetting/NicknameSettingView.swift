import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct NicknameSettingView: View {
    
    @Bindable var store: StoreOf<NicknameSettingFeature>
    // ✅ @FocusState는 isKeyboardVisible 상태와 바인딩됩니다.
    @FocusState private var isKeyboardVisible: Bool
    
    public init(store: StoreOf<NicknameSettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            imagePlaceholderSection
            titleSection
            textFieldSection
            Spacer()
            ctaButtonSection
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onTapGesture {
            store.send(.viewTapped)
        }
        // ✅ isKeyboardVisible 상태를 @FocusState와 바인딩합니다.
        .bind($store.isKeyboardVisible, to: $isKeyboardVisible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// MARK: - Private Views
private extension NicknameSettingView {
    
    var imagePlaceholderSection: some View {
        Rectangle()
            .fill(Color(uiColor: .systemGray5))
            .frame(width: 212, height: 183)
            .padding(.top, 60)
            .padding(.bottom, 48)
    }
    
    var titleSection: some View {
        Text(store.validationState.message)
            .font(Font.pretendard.display1)
            .foregroundStyle(store.validationState.messageColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .lineSpacing(6.2)
            .padding(.horizontal, 30)
            .padding(.bottom, 8)
    }
    
    var textFieldSection: some View {
        ZStack {
            if !store.isTextFieldActive {
                Text("닉네임을 입력해주세요")
                    .font(Font.pretendard.display1)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
            }
            
            TextField("", text: $store.nickname)
                .font(Font.pretendard.display1)
                .focused($isKeyboardVisible)
                .multilineTextAlignment(.center)
                .tint(Color.component.textfieldDisplay.focus.text)
            
            // ✅ 키보드가 내려갔을 때만 보이는 커스텀 커서
            if store.isTextFieldActive && !store.isKeyboardVisible && store.nickname.isEmpty {
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 30)
    }
    
    var ctaButtonSection: some View {
        CTAButton(
            title: "확인",
            action: {
                store.send(.doneButtonTapped)
            }
        )
        .disabled(!store.isCtaButtonEnabled)
    }
}

// MARK: - Custom Cursor View
private struct BlinkingCursorView: View {
    @State private var isVisible: Bool = false
    
    var body: some View {
        // ✅ Text 대신 Rectangle을 사용하여 커서 굵기를 직접 제어합니다.
        Rectangle()
            .fill(Color.component.textfieldDisplay.focus.text)
            .frame(width: 2, height: 35) // 너비 2pt, 높이 35pt로 실제 커서와 유사하게 설정
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                // 0.5초마다 타이머를 실행하여 깜빡이는 효과를 줍니다.
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
