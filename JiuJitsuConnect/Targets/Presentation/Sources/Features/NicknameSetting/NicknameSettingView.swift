import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct NicknameSettingView: View {
    
    @Bindable var store: StoreOf<NicknameSettingFeature>
    @FocusState private var isTextFieldFocused: Bool
    
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
        .bind($store.isTextFieldFocused, to: $isTextFieldFocused)
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// MARK: - Private Views
private extension NicknameSettingView {
    
    /// 상단 임시 이미지 영역 뷰
    var imagePlaceholderSection: some View {
        Rectangle()
            .fill(Color(uiColor: .systemGray5))
            .frame(width: 212, height: 183)
            .padding(.top, 60)
            .padding(.bottom, 48)
    }
    
    /// 안내 문구 또는 유효성 검사 메시지를 표시하는 뷰
    var titleSection: some View {
        Text(store.validationState.message)
            .font(Font.pretendard.display1)
            .foregroundStyle(store.validationState.messageColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 30)
            .padding(.bottom, 8)
    }
    
    /// 닉네임 입력 필드 뷰
    var textFieldSection: some View {
        TextField(store.textFieldPlaceHolder, text: $store.nickname)
            .font(Font.pretendard.display1)
            .focused($isTextFieldFocused)
            .multilineTextAlignment(.center)
            .tint(Color.component.textfieldDisplay.focus.text)
            .padding(.horizontal, 30)
    }
    
    /// "확인" CTA 버튼 뷰
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

#Preview {
    // Preview를 위한 NavigationStack 래핑
    NavigationStack {
        NicknameSettingView(
            store: Store(initialState: NicknameSettingFeature.State(tempToken: "test-token", isMarketingAgreed: false)) {
                NicknameSettingFeature()
            }
        )
    }
}
