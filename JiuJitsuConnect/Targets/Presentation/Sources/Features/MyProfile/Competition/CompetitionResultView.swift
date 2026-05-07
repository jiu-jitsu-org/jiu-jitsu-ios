import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

struct CompetitionResultView: View {
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
        Text("결과는 어떠했나요?")
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
                items: CompetitionRank.allCases,
                selectedItem: store.result,
                displayText: { $0.displayName },
                width: 140,
                onSelect: { rank in
                    store.send(.view(.resultSelected(rank)))
                }
            )
            Spacer()
        }
        .padding(.top, 40)
    }

    private var confirmButton: some View {
        CTAButton(
            title: "완료",
            type: .blue,
            style: .keypad,
            height: 56,
            action: {
                store.send(.view(.nextButtonTapped))
            }
        )
    }
}
