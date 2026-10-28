import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

struct CompetitionNameView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>
    // 포커스는 이 화면에서만 쓰므로 Feature 상태로 올리지 않고 View에 둔다.
    @State private var isKeyboardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            titleSection
            textFieldSection
            // 목록이 있으면 버튼 위 남은 공간을 목록이 채우고, 없으면 빈 공간으로 버튼을 키보드 위에 붙인다.
            if store.suggestions.isEmpty {
                Spacer()
            } else {
                suggestionSection
            }
            namelessButton
            ctaButtonSection
        }
        .onAppear {
            // 화면 진입 시 자동 포커스로 키보드 노출
            isKeyboardVisible = true
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        Text("어떤 대회였나요?")
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            // 자동완성 목록이 키보드 위에 보일 자리를 만들려고 다른 단계와 같은 상단 여백을 쓴다.
            .padding(.top, 40)
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

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("등록된 대회")
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.list.setting.subText)
                .padding(.horizontal, 4)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(store.suggestions, id: \.name) { competition in
                        CompetitionSuggestionRow(
                            name: competition.name,
                            keyword: store.name,
                            onTapped: { store.send(.view(.suggestionTapped(competition))) }
                        )
                    }
                }
                .padding(.vertical, 4)
                .background(Color.component.list.setting.background)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    // 자동완성으로도 못 찾은 사람이 기록을 포기하지 않게 이름 없이 넘어가는 길(#125).
    // 이름 없는 기록은 대회명을 채우기 전까지 나만 보이므로, 그 사실은 완료 화면과 프로필에서 알려 준다.
    private var namelessButton: some View {
        Button {
            store.send(.view(.namelessButtonTapped))
        } label: {
            Text("대회명이 기억나지 않아요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.subText)
                .underline()
                .frame(height: 44)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
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
        // 대회명이 비어있으면(공백만 입력 포함) 다음 단계로 넘어갈 수 없다 — 처음부터 비활성화한다.
        .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

// MARK: - Suggestion Row

/// 등록된 대회 한 줄 — 입력한 글자와 맞는 부분을 강조해 왜 이 대회가 떴는지 보이게 한다.
private struct CompetitionSuggestionRow: View {
    let name: String
    let keyword: String
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            Text(highlightedName)
                .font(Font.pretendard.bodyM)
                .foregroundStyle(Color.component.list.setting.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var highlightedName: AttributedString {
        var attributed = AttributedString(name)
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty,
           let range = attributed.range(of: trimmed, options: .caseInsensitive) {
            attributed[range].foregroundColor = Color.component.textfieldDisplay.focus.text
        }
        return attributed
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

// MARK: - Preview

#Preview("자동완성 목록") {
    var state = CompetitionInfoFeature.State()
    state.step = .name
    state.name = "서울"
    state.suggestions = [
        RegisteredCompetition(id: 1, name: "2026 서울 오픈"),
        RegisteredCompetition(id: 2, name: "서울 주짓수 챔피언십"),
        RegisteredCompetition(id: 3, name: "서울 국제 오픈")
    ]
    return CompetitionNameView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
