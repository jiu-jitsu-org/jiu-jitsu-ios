import SwiftUI
import ComposableArchitecture
import DesignSystem

struct CompetitionDateView: View {
    let store: StoreOf<CompetitionInfoFeature>

    private let years: [YearItem] = (2020...2025).reversed().map(YearItem.init)
    private let months: [MonthItem] = (1...12).reversed().map(MonthItem.init)

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
        Text("언제 출전했나요?")
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 36)
            .padding(.horizontal, 20)
            .padding(.top, 40)
    }

    private var pickerSection: some View {
        HStack(spacing: 24) {
            Spacer()

            HStack(spacing: 4) {
                SheetPickerView(
                    items: years,
                    selectedItem: YearItem(value: store.year),
                    displayText: { String($0.value) },
                    width: 110,
                    onSelect: { item in
                        store.send(.view(.yearSelected(item.value)))
                    }
                )

                Text("년")
                    .font(Font.pretendard.title2)
                    .foregroundStyle(Color.component.sectionHeader.title)
            }

            HStack(spacing: 4) {
                SheetPickerView(
                    items: months,
                    selectedItem: MonthItem(value: store.month),
                    displayText: { String($0.value) },
                    width: 90,
                    onSelect: { item in
                        store.send(.view(.monthSelected(item.value)))
                    }
                )

                Text("월")
                    .font(Font.pretendard.title2)
                    .foregroundStyle(Color.component.sectionHeader.title)
            }

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

// MARK: - Picker Items

private struct YearItem: Identifiable, Hashable {
    let value: Int
    var id: Int { value }
}

private struct MonthItem: Identifiable, Hashable {
    let value: Int
    var id: Int { value }
}
