import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct NicknameSettingView: View {
    
    @Bindable var store: StoreOf<NicknameSettingFeature>
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
            // MARK: - 보여주기용 뷰 (Display View)
            
            // 정책 1: 초기 상태에서 플레이스홀더를 보여줍니다.
            if !store.isTextFieldActive {
                Text("닉네임을 입력해주세요")
                    .font(Font.pretendard.display1)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
            } else {
                // 정책 2 & 3: 사용자가 입력을 시작한 후
                // 실제 텍스트를 보여주거나,
                // 텍스트가 비어있으면 커스텀 커서를 보여줍니다.
                Text(store.nickname)
                    .font(Font.pretendard.display1)
                    .foregroundStyle(store.validationState.textColor)
                
                // 정책 3: 입력 필드가 비어있고, 사용자가 입력을 시작한 상태라면
                // 키보드 상태와 관계없이 커스텀 커서를 보여줍니다.
                if store.nickname.isEmpty {
                    BlinkingCursorView()
                        .allowsHitTesting(false)
                }
            }
            
            // MARK: - 입력용 뷰 (Input View)
            // 실제 키보드 입력을 처리하는 보이지 않는 TextField입니다.
            TextField("", text: $store.nickname)
                .font(Font.pretendard.display1)
                .focused($isKeyboardVisible)
                .multilineTextAlignment(.center)
                // 정책 1: 초기 상태에서는 네이티브 커서를 숨깁니다.
                // 정책 2: 입력 시작 후에는 네이티브 커서를 보여줍니다.
                .tint(store.isTextFieldActive ? Color.component.textfieldDisplay.focus.text : .clear)
                // 입력 처리를 위해 항상 투명하게 유지합니다.
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, 30)
    }
    
    var ctaButtonSection: some View {
        CTAButton(
            title: "확인",
            type: .blue,
            style: .keypad,
            height: 56,
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
