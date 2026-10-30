import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

struct CompetitionNameView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>
    // 포커스는 이 화면에서만 쓰므로 Feature 상태로 올리지 않고 View에 둔다.
    @State private var isKeyboardVisible = false
    // 목록이 넘칠 때 위·아래 끝을 흐리게 해 더 있다는 걸 알린다(선이나 개수 글자 대신).
    @State private var suggestionFade = SuggestionFade()

    private enum Metrics {
        // 키보드 위 좁은 자리라 앞에서 이만큼만 보여 주고, 더 있으면 더 쳐서 좁히게 한다.
        static let suggestionLimit = 20
        static let topFadeHeight: CGFloat = 24
        static let bottomFadeHeight: CGFloat = 48
        // 끝까지 지우지 않고 옅게 남겨, 다음 줄이 살짝 비쳐 보이게 한다.
        static let bottomFadeOpacity: CGFloat = 0.15
    }

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
            ctaButtonSection
        }
        .onAppear {
            // 화면 진입 시 자동 포커스로 키보드 노출
            isKeyboardVisible = true
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        Text("대회명이 뭐였나요?")
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

    // 위의 큰 질문·입력과 한 기둥으로 읽히도록 머리줄·면 없이 가운데 정렬로 둔다.
    private var suggestionSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 공개 일정 대회는 이름이 같고 연도만 다를 수 있어 이름 대신 순서로 구분한다.
                ForEach(Array(store.suggestions.prefix(Metrics.suggestionLimit).enumerated()), id: \.offset) { _, competition in
                    CompetitionSuggestionRow(
                        name: competition.name,
                        year: competition.year,
                        keyword: store.name,
                        onTapped: { store.send(.view(.suggestionTapped(competition))) }
                    )
                }
                // 끝까지 내려온 사람에게만 보이도록 목록 맨 끝에 둔다.
                if store.suggestions.count > Metrics.suggestionLimit {
                    Text("대회명을 더 정확히 입력해 보세요")
                        .font(Font.pretendard.labelM)
                        .foregroundStyle(Color.component.list.setting.subText)
                        .frame(height: 44)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: SuggestionFade.self) { geometry in
            SuggestionFade(
                top: geometry.visibleRect.minY > 1,
                bottom: geometry.visibleRect.maxY < geometry.contentSize.height - 1
            )
        } action: { _, fade in
            suggestionFade = fade
        }
        .mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: suggestionFade.top ? Metrics.topFadeHeight : 0)
                Rectangle()
                LinearGradient(
                    colors: [.black, .black.opacity(Metrics.bottomFadeOpacity)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: suggestionFade.bottom ? Metrics.bottomFadeHeight : 0)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 16)
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
/// 공개 일정에서 온 대회는 이름 뒤에 연도를 보여 줘, 고르면 연도가 그 해로 맞춰진다는 걸 미리 알 수 있게 한다(#126).
private struct CompetitionSuggestionRow: View {
    let name: String
    let year: Int?
    let keyword: String
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: 6) {
                Text(highlightedName)
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.component.list.setting.subText)
                    .lineLimit(1)

                // 이름에 이미 연도가 있으면("2026 서울 오픈") 반복하지 않는다.
                if let year, !name.contains(String(year)) {
                    Text(String(year))
                        .font(Font.pretendard.bodyS)
                        .foregroundStyle(Color.component.textfieldDisplay.default.placeholder)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var highlightedName: AttributedString {
        var attributed = AttributedString(name)
        if let range = Self.matchRange(in: name, keyword: keyword),
           let lower = AttributedString.Index(range.lowerBound, within: attributed),
           let upper = AttributedString.Index(range.upperBound, within: attributed) {
            attributed[lower..<upper].foregroundColor = Color.component.textfieldDisplay.focus.text
        }
        return attributed
    }

    /// 띄어쓰기를 빼고 맞춰 본 뒤 원래 이름의 구간으로 돌려준다 — '서울오픈'으로 쳐도 '서울 오픈'이 강조된다.
    private static func matchRange(in name: String, keyword: String) -> Range<String.Index>? {
        let positions = name.indices.filter { !name[$0].isWhitespace }
        let letters = positions.map { name[$0].lowercased() }
        let target = keyword.filter { !$0.isWhitespace }.map { $0.lowercased() }
        guard !target.isEmpty, target.count <= letters.count else { return nil }
        for start in 0...(letters.count - target.count)
        where Array(letters[start..<(start + target.count)]) == target {
            let last = positions[start + target.count - 1]
            return positions[start]..<name.index(after: last)
        }
        return nil
    }
}

/// 목록의 위·아래에 가려진 후보가 있는지.
private struct SuggestionFade: Equatable {
    var top = false
    var bottom = false
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
        RegisteredCompetition(id: 1, name: "2026 서울 오픈", year: 2026),
        RegisteredCompetition(id: 2, name: "서울 주짓수 챔피언십"),
        RegisteredCompetition(id: 3, name: "서울 국제 오픈", year: 2025)
    ]
    return CompetitionNameView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
