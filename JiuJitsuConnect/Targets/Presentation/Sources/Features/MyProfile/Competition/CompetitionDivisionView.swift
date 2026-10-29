import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

/// 4단계: 출전 부문 — 체급(숫자 + 이하/초과)을 묻고, 도복/노기·앱솔루트·출전 띠는 곁들여 고친다.
///
/// 대회 정보는 한 화면에 하나씩 묻는다. 크게 묻는 건 체급 하나라 체급 숫자를 화면에서 가장 크게 두고,
/// 도복/노기는 그 체급의 조건이라 위에 작게, 앱솔루트·출전 띠는 아래 한 줄에 글자 크기로만 둔다.
/// 체급표는 단체·대회마다 달라 표에서 고르지 않고 숫자로 받는다.
/// 기억이 안 나거나 귀찮은 사람도 기록을 남기도록 모두 선택 사항이고 '건너뛰기'로 넘길 수 있다.
struct CompetitionDivisionView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>

    @FocusState private var isWeightFocused: Bool
    // 입력칸이 직접 들고 있는 글자. 다듬은 값이 store에 이미 있던 값과 같으면 TextField가
    // 다시 그려지지 않아 막은 글자가 남아 보이므로, 칸 쪽에서 되돌린 뒤 store에 넘긴다.
    @State private var weightInput = ""

    private enum Metrics {
        static let segmentWidth: CGFloat = 160
        static let optionRowHeight: CGFloat = 40
        static let chipSpacing: CGFloat = 8
        static let iconSize: CGFloat = 18
        static let toggleArrowSize: CGFloat = 10
        // "100.5"까지 들어가는 폭. 입력할 때마다 칸이 늘었다 줄지 않게 고정한다.
        static let weightBoxWidth: CGFloat = 150
        static let weightBoxHeight: CGFloat = 72
        static let weightBoxCornerRadius: CGFloat = 16
        // 숫자와 kg은 한 덩어리로 보이되 붙어 보이지 않게, 이하/초과는 그보다 한 칸 더 떼어 별개 값으로 보이게.
        static let boxUnitSpacing: CGFloat = 12
        static let unitBoundSpacing: CGFloat = 20
        // 칸 밖 24pt 'kg'는 g의 꼬리 때문에 처져 보여 숫자 칸 가운데에 맞게 올린다(시뮬레이터 실측).
        static let unitOpticalOffset: CGFloat = -2.7
    }

    // 체급 숫자가 화면에서 가장 위계가 높다 — 질문 제목(30pt)보다 크게.
    private static let weightFont = Font.pretendard.custom(weight: .semiBold, size: 48)

    // 펼치고 접는 건 한 동작으로 본다(기본 500ms).
    private static let expandAnimation: Animation = .easeInOut(duration: 0.5)

    var body: some View {
        VStack(spacing: 0) {
            // 내용이 짧아 위에 몰리지 않게, 남는 높이 안에서 세로 가운데에 둔다.
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        titleSection
                            .padding(.bottom, 40)

                        uniformSegment
                            .padding(.bottom, 32)

                        weightSection
                            .padding(.bottom, 24)

                        optionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }

            buttonSection
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        Text("어떤 체급으로 나갔나요?")
            .font(Font.pretendard.display1)
            .foregroundStyle(Color.component.textfieldDisplay.focus.title)
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// 도복/노기 — 체급의 조건이라 질문 바로 아래 작게 둔다.
    private var uniformSegment: some View {
        SegmentControl(
            leftItem: SegmentItem(title: CompetitionUniform.gi.displayName),
            rightItem: SegmentItem(title: CompetitionUniform.noGi.displayName),
            selectedSide: store.uniform.map { $0 == .gi ? .left : .right },
            size: .compact
        ) { side in
            store.send(.view(.uniformSelected(side == .left ? .gi : .noGi)))
        }
        .frame(width: Metrics.segmentWidth)
        .frame(maxWidth: .infinity)
    }

    /// 체급 — "[ 76 ] kg 이하⌃⌄". 바꿀 수 있는 숫자만 칸에 담고, kg·이하는 칸 밖 글자로 둔다.
    private var weightSection: some View {
        HStack(spacing: 0) {
            weightNumberBox
            weightUnit
                .padding(.leading, Metrics.boxUnitSpacing)
            weightBoundToggle
                .padding(.leading, Metrics.unitBoundSpacing)
        }
        .frame(maxWidth: .infinity)
    }

    /// 숫자만 담은 칸 — 숫자 길이와 상관없이 폭을 고정해 칠 때 흔들리지 않게 한다.
    private var weightNumberBox: some View {
        TextField(
            "",
            text: $weightInput,
            prompt: Text("00").foregroundStyle(Color.semantic.text.tertiary)
        )
        .font(Self.weightFont)
        .foregroundStyle(Color.component.textfieldDisplay.focus.text)
        .tint(Color.component.textfieldDisplay.focus.text)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .focused($isWeightFocused)
        .accessibilityLabel("체급, 킬로그램")
        .onAppear { weightInput = store.weightText }
        .onChange(of: weightInput) { oldValue, newValue in
            // 정수가 3자리를 넘으면(1000 붙여넣기 등) 잘라서 다른 값으로 바꾸지 않고 입력 전으로 되돌린다.
            let integerDigits = newValue.prefix { $0 != "." && $0 != "," }.filter(\.isNumber).count
            let accepted = integerDigits > 3 ? oldValue : CompetitionInfoFeature.sanitizedWeightText(newValue)
            if accepted != newValue { weightInput = accepted }
            if store.weightText != accepted { store.weightText = accepted }
        }
        .frame(width: Metrics.weightBoxWidth, height: Metrics.weightBoxHeight)
        .background(Color.component.picker.itemSelectedBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.weightBoxCornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { isWeightFocused = true }
    }

    /// 프로필 체급 설정의 kg와 같은 크기·색
    private var weightUnit: some View {
        Text("kg")
            .font(Font.pretendard.custom(weight: .medium, size: 24))
            .foregroundStyle(Color.component.picker.unit)
            .offset(y: Metrics.unitOpticalOffset)
    }

    /// 이하/초과 — 위아래 꺾쇠로 눌러서 바꾸는 값임을 알린다.
    private var weightBoundToggle: some View {
        Button {
            store.send(.view(.weightBoundToggled))
        } label: {
            HStack(spacing: 4) {
                Text(store.weightBound == .under ? "이하" : "초과")
                    .font(Font.pretendard.bodyM)

                VStack(spacing: 0) {
                    ForEach([-90.0, 90.0], id: \.self) { degrees in
                        Assets.Common.Icon.chevronRight.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metrics.toggleArrowSize, height: Metrics.toggleArrowSize)
                            .rotationEffect(.degrees(degrees))
                    }
                }
            }
            .foregroundStyle(Color.semantic.text.secondary)
            .frame(height: Metrics.weightBoxHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.weightBound == .under ? "이하, 눌러서 초과로 바꾸기" : "초과, 눌러서 이하로 바꾸기")
    }

    /// 앱솔루트·출전 띠 — 같은 위계의 곁가지라 한 줄에 글자 크기로 나란히 둔다.
    /// 출전 띠를 누르면 그 아래로 띠 칩을 펼친다.
    private var optionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                absoluteToggle
                beltToggle
            }
            .frame(maxWidth: .infinity)

            if store.isBeltExpanded {
                beltChips
            }
        }
    }

    /// 앱솔루트 — 체급과 별개 부문이라 체크 하나로 따로 받는다.
    private var absoluteToggle: some View {
        Button {
            store.send(.view(.absoluteToggled))
        } label: {
            HStack(spacing: 4) {
                Assets.Common.Icon.check.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(
                        store.isAbsolute
                        ? Color.component.bottomSheet.selected.listItem.leadingIcon
                        : Color.component.bottomSheet.unselected.listItem.leadingIcon
                    )

                Text("앱솔루트")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(
                        store.isAbsolute
                        ? Color.component.bottomSheet.selected.listItem.label
                        : Color.component.bottomSheet.unselected.listItem.label
                    )
            }
            .frame(height: Metrics.optionRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.isAbsolute ? .isSelected : [])
    }

    /// 출전 띠는 지금 띠로 채워 두고 "출전 띠 블루 ›"로 접어 둔다. 누르면 아래로 펼쳐 고친다.
    private var beltToggle: some View {
        Button {
            store.send(.view(.beltRowTapped), animation: Self.expandAnimation)
        } label: {
            HStack(spacing: 4) {
                Text("출전 띠")
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.label)

                Text(store.belt?.displayName ?? "선택 안 함")
                    .foregroundStyle(Color.semantic.text.primary)

                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.followingIcon)
                    .rotationEffect(.degrees(store.isBeltExpanded ? 90 : 0))
            }
            .font(Font.pretendard.bodyS)
            .frame(height: Metrics.optionRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(store.isBeltExpanded ? "펼침" : "접힘")
    }

    private var beltChips: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: Metrics.chipSpacing),
                count: BeltRank.allCases.count
            ),
            spacing: Metrics.chipSpacing
        ) {
            ForEach(BeltRank.allCases) { belt in
                Button {
                    store.send(.view(.beltSelected(belt)), animation: Self.expandAnimation)
                } label: {
                    Text(belt.displayName)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
                .appButtonStyle(store.belt == belt ? .primary : .neutral, size: .medium, height: 40, horizontalPadding: 4)
                .accessibilityAddTraits(store.belt == belt ? .isSelected : [])
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

            // 수정은 보이는 값을 그대로 저장하므로(비우려면 입력을 지우거나 체크를 해제) 건너뛰기는 새 기록에만 둔다.
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

// MARK: - Preview

#Preview {
    var state = CompetitionInfoFeature.State(mode: .add, currentBelt: .brown)
    state.step = .division
    state.weightText = "76"
    return CompetitionDivisionView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
