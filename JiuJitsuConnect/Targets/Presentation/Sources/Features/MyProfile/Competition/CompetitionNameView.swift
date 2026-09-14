import SwiftUI
import ComposableArchitecture
import DesignSystem

struct CompetitionNameView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>
    // 포커스는 이 화면에서만 쓰므로 Feature 상태로 올리지 않고 View에 둔다.
    @State private var isKeyboardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            titleSection
            textFieldSection
            Spacer()
            ctaButtonSection
        }
        .onAppear {
            // 화면 진입 시 자동 포커스로 키보드 노출
            isKeyboardVisible = true
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        Text("대회명을 입력해주세요")
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .padding(.top, 120)
            .padding(.bottom, 8)
    }

    private var textFieldSection: some View {
        ZStack {
            // 입력 값이 비어있을 때 깜빡이는 커스텀 커서 표시
            // (가운데 정렬 필드는 빈 상태에서 네이티브 커서가 보이지 않음)
            if store.name.isEmpty {
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }

            // 긴 대회명은 줄바꿈해서 보여주고, Return은 개행 없이 다음 버튼과 동일하게 처리한다.
            MultilineTextField(
                text: $store.name,
                isFocused: $isKeyboardVisible,
                font: UIFont.pretendard.display1,
                textColor: Color.component.textfieldDisplay.focus.text,
                // 빈 상태에서는 네이티브 커서 숨기고 커스텀 커서 사용
                tintColor: store.name.isEmpty ? .clear : Color.component.textfieldDisplay.focus.text,
                onSubmit: { store.send(.view(.nextButtonTapped)) }
            )
        }
        .padding(.horizontal, 30)
    }

    private var ctaButtonSection: some View {
        CTAButton(
            title: "다음",
            type: .blue,
            style: .keypad,
            height: 56,
            action: {
                store.send(.view(.nextButtonTapped))
            }
        )
        // 대회명이 비어있으면(공백만 입력 포함) 진행 불가 — 처음부터 비활성화한다.
        .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty)
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
