import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

/// 4단계: 출전 부문 — 도복/노기, 체급(또는 앱솔루트), 출전 띠.
///
/// 기억이 안 나거나 귀찮은 사람도 기록을 남기도록 세 항목 모두 선택 사항이고 '건너뛰기'로 넘길 수 있다.
struct CompetitionDivisionView: View {
    let store: StoreOf<CompetitionInfoFeature>

    private enum Metrics {
        static let chipSpacing: CGFloat = 8
        static let weightClassColumnCount = 4
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    titleSection
                    uniformSection
                    weightClassSection
                    beltSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            buttonSection
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("어떤 부문에 나갔나요?")
                .font(Font.pretendard.display1)
                .foregroundStyle(Color.component.textfieldDisplay.focus.title)
                .frame(height: 36)

            Text("모르면 비워 두거나 건너뛰어도 괜찮아요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }

    private var uniformSection: some View {
        DivisionSection(title: "도복 / 노기") {
            HStack(spacing: Metrics.chipSpacing) {
                ForEach(CompetitionUniform.allCases) { uniform in
                    DivisionChip(
                        title: uniform.displayName,
                        isSelected: store.uniform == uniform,
                        action: { store.send(.view(.uniformSelected(uniform))) }
                    )
                }
            }
        }
    }

    private var weightClassSection: some View {
        DivisionSection(title: "체급") {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Metrics.chipSpacing),
                    count: Metrics.weightClassColumnCount
                ),
                spacing: Metrics.chipSpacing
            ) {
                ForEach(CompetitionWeightClass.allCases) { weightClass in
                    DivisionChip(
                        title: weightClass.displayName,
                        isSelected: store.weightClass == weightClass,
                        action: { store.send(.view(.weightClassSelected(weightClass))) }
                    )
                }
            }
        }
    }

    private var beltSection: some View {
        DivisionSection(title: "출전 띠") {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Metrics.chipSpacing),
                    count: BeltRank.allCases.count
                ),
                spacing: Metrics.chipSpacing
            ) {
                ForEach(BeltRank.allCases) { belt in
                    DivisionChip(
                        title: belt.displayName,
                        isSelected: store.belt == belt,
                        action: { store.send(.view(.beltSelected(belt))) }
                    )
                }
            }
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 4) {
            CTAButton(
                title: "완료",
                action: {
                    store.send(.view(.nextButtonTapped))
                }
            )

            // 수정은 보이는 값을 그대로 저장하므로(비우려면 칩을 다시 눌러 해제) 건너뛰기는 새 기록에만 둔다.
            if !store.mode.isEdit {
                Button {
                    store.send(.view(.skipButtonTapped))
                } label: {
                    AppButtonConfiguration(title: "건너뛰기", size: .medium)
                }
                .appButtonStyle(.text, size: .medium, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, store.mode.isEdit ? 24 : 8)
    }
}

// MARK: - Section

private struct DivisionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.sectionHeader.label)

            content
        }
    }
}

// MARK: - Chip

/// 부문 선택 칩 — 고른 칩을 다시 누르면 선택이 풀린다(Feature에서 처리).
private struct DivisionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .appButtonStyle(isSelected ? .primary : .neutral, size: .medium, height: 40, horizontalPadding: 4)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    var state = CompetitionInfoFeature.State(mode: .add, currentBelt: .brown)
    state.step = .division
    state.weightClass = .under76
    return CompetitionDivisionView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
