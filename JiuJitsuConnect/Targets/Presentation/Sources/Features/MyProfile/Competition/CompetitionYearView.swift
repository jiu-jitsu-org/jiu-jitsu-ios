import SwiftUI
import ComposableArchitecture
import DesignSystem

struct CompetitionYearView: View {
    let store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            titleSection
            pickerSection
            Spacer()
            confirmButton
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        Text("몇 년도 대회였나요?")
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 36)
            .padding(.horizontal, 20)
            .padding(.top, 40)
    }

    private var pickerSection: some View {
        HStack {
            Spacer()
            SheetPickerView(
                items: CompetitionInfoFeature.YearOption.options(currentYear: store.currentYear),
                selectedItem: CompetitionInfoFeature.YearOption(year: store.year, currentYear: store.currentYear),
                displayText: { $0.displayText },
                width: 140,
                onSelect: { option in
                    store.send(.view(.yearOptionSelected(option)))
                }
            )
            Spacer()
        }
        .padding(.top, 40)
    }

    private var confirmButton: some View {
        CTAButton(
            title: "다음",
            action: {
                store.send(.view(.nextButtonTapped))
            }
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    var state = CompetitionInfoFeature.State()
    state.step = .year
    return CompetitionYearView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
