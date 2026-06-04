import SwiftUI
import ComposableArchitecture
import DesignSystem

struct CompetitionNameView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>
    @FocusState private var isKeyboardVisible: Bool

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
            // (TextField는 multilineTextAlignment(.center)이라 빈 상태에서 커서가 보이지 않음)
            if store.name.isEmpty {
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }

            TextField("", text: $store.name)
                .font(Font.pretendard.display1)
                .focused($isKeyboardVisible)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.component.textfieldDisplay.focus.text)
                // 빈 상태에서는 네이티브 커서 숨기고 커스텀 커서 사용
                .tint(store.name.isEmpty ? .clear : Color.component.textfieldDisplay.focus.text)
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
