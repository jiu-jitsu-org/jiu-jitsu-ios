import SwiftUI
import ComposableArchitecture
import DesignSystem

struct CompetitionYearView: View {
    let store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            titleSection
            pickerSection
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
        // 메달 단계와 같은 크기·자리. 제목과 버튼 사이 빈 곳 전체가 끌기 영역이다.
        SheetPickerView(
            items: store.yearOptions,
            selectedItem: CompetitionInfoFeature.YearOption(year: store.year),
            displayText: { $0.displayText },
            width: CompetitionWheelPickerMetrics.width,
            itemHeight: CompetitionWheelPickerMetrics.itemHeight,
            dragArea: .fill(
                verticalOffset: CompetitionWheelPickerMetrics.verticalOffset,
                minimumTopSpacing: CompetitionWheelPickerMetrics.minimumTopSpacing
            ),
            onSelect: { option in
                store.send(.view(.yearOptionSelected(option)))
            }
        )
        .frame(maxHeight: .infinity)
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
