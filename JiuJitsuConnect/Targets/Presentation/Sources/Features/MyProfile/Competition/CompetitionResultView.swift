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
                icon: { $0.medalImage },
                width: 160,
                onSelect: { rank in
                    store.send(.view(.resultSelected(rank)))
                }
            )
            Spacer()
        }
        .padding(.top, 40)
    }

    private var confirmButton: some View {
        // 키보드가 없는 단계라 날짜 단계와 같은 둥근 버튼을 쓴다. 키패드형은 키보드가 올라오는 대회명 단계만.
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
