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
        // 제목과 버튼 사이 빈 곳 전체가 끌기 영역이다. 휠은 그 빈 곳의 가운데보다 조금 위에 둔다.
        SheetPickerView(
            items: CompetitionRank.allCases,
            selectedItem: store.result,
            displayText: { $0.displayName },
            icon: { $0.medalImage },
            width: CompetitionWheelPickerMetrics.width,
            itemHeight: CompetitionWheelPickerMetrics.itemHeight,
            dragArea: .fill(
                verticalOffset: CompetitionWheelPickerMetrics.verticalOffset,
                minimumTopSpacing: CompetitionWheelPickerMetrics.minimumTopSpacing
            ),
            onSelect: { rank in
                store.send(.view(.resultSelected(rank)))
            }
        )
        .frame(maxHeight: .infinity)
    }

    private var confirmButton: some View {
        // 키보드가 없는 단계라 연도 단계와 같은 둥근 버튼을 쓴다. 키패드형은 키보드가 올라오는 대회명 단계만.
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

/// 대회 정보 추가의 메달·연도 휠 — 두 단계가 같은 크기·같은 자리에 오도록 한곳에서 맞춘다.
enum CompetitionWheelPickerMetrics {
    // 큰 기기에서도 한 손 엄지로 굴리기 쉽게 칸을 키운다(기본 130×45).
    static let width: CGFloat = 200
    static let itemHeight: CGFloat = 56
    // 제목과 버튼 사이 정가운데는 아래로 처져 보여, 선택 칸을 조금 위로 올린다.
    static let verticalOffset: CGFloat = -80
    // 작은 화면(SE)에서 위로 올린 휠이 제목에 붙지 않게 남기는 최소 간격
    static let minimumTopSpacing: CGFloat = 24
}
