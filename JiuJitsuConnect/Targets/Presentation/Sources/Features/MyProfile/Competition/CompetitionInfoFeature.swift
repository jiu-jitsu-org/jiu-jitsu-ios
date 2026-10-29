//
//  CompetitionInfoFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import CoreKit
import Domain
import DesignSystem

@Reducer
public struct CompetitionInfoFeature: Sendable {

    private enum CancelID {
        case searchCompetitions
        case toast
    }

    // 한 글자씩 칠 때마다 검색하지 않도록, 입력이 잠깐 멈춘 뒤에 검색한다.
    private static let searchDebounce: Duration = .milliseconds(300)

    public init() {}

    public enum Mode: Equatable, Sendable {
        case add
        case edit(original: Competition)

        var isEdit: Bool {
            if case .edit = self { return true }
            return false
        }

        var headerTitle: String {
            switch self {
            case .add: return "대회 정보 추가"
            case .edit: return "대회 정보 수정"
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        var mode: Mode = .add
        var step: Step = .result

        // 이번 흐름에서 저장한 기록(첫 기록 + '부문 추가'로 더한 기록). 완료 화면에 한 줄씩 보여 준다.
        // 하나라도 있으면 그다음 입력은 '부문 추가' — 대회명·연도는 그대로 두고 메달과 부문만 다시 묻는다(#123).
        var savedRecords: [Competition] = []
        var isSaving = false
        // 이번 흐름에서 실제로 저장했는지. 프로필에서 '부문 추가'로 들어오면 savedRecords가 미리 차 있어
        // 그것만으로는 '돌아갈 완료 화면이 있는지' 알 수 없다.
        var hasSavedInThisFlow = false
        // 완료 화면 꽃가루 — 방금 저장했을 때만 터뜨리고, 뒤로 가기로 돌아왔을 때는 다시 터뜨리지 않는다.
        var celebratesOnDone = false
        // 저장 실패 안내. 이 화면이 MY 화면 위에 push돼 있어 MY 화면 토스트는 가려지므로 여기서 띄운다.
        var toast: ToastState?

        var isAddingDivision: Bool { !savedRecords.isEmpty }

        /// 지금 흐름에서 입력받는 단계 — 진행 막대 칸 수와 위치의 기준.
        var inputSteps: [Step] {
            isAddingDivision ? [.result, .division] : [.result, .name, .year, .division]
        }

        var headerTitle: String {
            isAddingDivision && step != .done ? "부문 추가" : mode.headerTitle
        }

        // 1단계: 결과 — Picker UI 특성상 초기 선택값이 필요하므로 옵셔널이 아닌 기본값 사용
        var result: CompetitionRank = .gold

        // 2단계: 대회명 (TextField 직접 바인딩)
        // 대회명은 닉네임과 달리 중복을 허용하므로 별도 검증 없이 "빈 값" 여부만 본다.
        // 빈 값이면 다음 버튼을 비활성화하므로(View의 .disabled) 별도 검증 상태/문구는 두지 않는다.
        // 이름이 기억나지 않으면 '대회명이 기억나지 않아요'로 빈 이름인 채 넘어간다(#125, 나만 보기로 저장).
        var name: String = ""

        // 입력한 대회명과 맞는 등록된 대회 목록. 고르면 이름이 채워지고, 없으면 직접 입력한 이름을 그대로 쓴다.
        var suggestions: [RegisteredCompetition] = []

        // 3단계: 연도 — 몇 월이었는지는 기억이 가장 흐려 입력이 막히므로 연도만 받는다.
        // 기본 선택은 올해.
        let currentYear: Int = Calendar.current.component(.year, from: Date())
        var year: Int = Calendar.current.component(.year, from: Date())

        // 휠 목록은 연도를 미리 골라 둘 때만 다시 만든다. 휠을 굴릴 때마다 고른 연도로 목록 끝이 바뀌면
        // (예: 내년 대회를 골라 둔 뒤 올해로 굴림) 칸이 밀려 다른 연도가 저장된다.
        private(set) var yearOptions: [YearOption] = YearOption.options(
            currentYear: Calendar.current.component(.year, from: Date()),
            including: Calendar.current.component(.year, from: Date())
        )

        // 추천 대회를 골라 연도를 바꾸기 전의 연도. 고른 뒤 대회명을 고쳐 쓰거나 '기억나지 않아요'를 누르면
        // 그 대회가 아니므로 이 연도로 되돌린다.
        var yearBeforeSuggestion: YearBeforeSuggestion?

        // 4단계: 출전 부문 — 건너뛸 수 있다. 출전 띠는 고른 칩을 다시 누르면 선택이 풀린다.
        // 도복 대회가 더 흔해 새 기록은 도복으로, 출전 띠는 지금 띠로 미리 골라 둔다(대부분 그대로 '완료'만 누르게).
        var uniform: CompetitionUniform? = .gi
        var belt: BeltRank?

        // 체급은 단체·대회마다 표가 달라 숫자로 받는다(TextField 직접 바인딩, 소수점 허용).
        // 대부분 '이하' 체급이라 이하를 기본으로 두고, 가장 무거운 체급만 '초과'로 바꾼다.
        var weightText: String = ""
        var weightBound: CompetitionWeightLimit.Bound = .under

        // 앱솔루트는 체급과 별개 부문이라 따로 체크한다.
        var isAbsolute = false

        /// 입력한 체급 — 숫자로 읽히지 않거나 0 이하면 체급 없음.
        var weightLimit: CompetitionWeightLimit? {
            let normalized = weightText.replacingOccurrences(of: ",", with: ".")
            guard let kg = Double(normalized), kg > 0 else { return nil }
            return CompetitionWeightLimit(kg: kg, bound: weightBound)
        }

        // 미리 골라 둔 값과 사람이 직접 고른 값을 '건너뛰기'에서 구분하려고 둔다.
        // 체급·앱솔루트는 미리 채우지 않으므로 값이 있으면 직접 고른 것이다.
        var didPickUniform = false
        var didPickBelt = false

        // 출전 띠는 대부분 지금 띠 그대로라 접어 두고, 줄을 누르면 펼친다.
        var isBeltExpanded = false

        public init() {}

        /// - Parameter currentBelt: 지금 프로필 띠. 새 기록의 출전 띠 기본값으로 쓴다.
        public init(mode: Mode, currentBelt: BeltRank? = nil) {
            self.mode = mode
            switch mode {
            case .add:
                self.belt = currentBelt
            case let .edit(original):
                self.preselectYear(original.competitionYear)
                self.name = original.competitionName
                self.result = original.competitionRank
                // 수정은 저장된 값을 그대로 보여 준다. 부문 없이 저장된 기록에 기본값을 채우면
                // 이름만 고치려던 사람이 모르는 사이 부문까지 저장하게 되므로 비워 둔다.
                self.uniform = original.competitionUniform
                if let weightLimit = original.competitionWeightLimit {
                    self.weightText = weightLimit.kgText
                    self.weightBound = weightLimit.bound
                }
                self.isAbsolute = original.competitionAbsolute
                self.belt = original.competitionBelt
            }
        }

        /// 연도를 미리 골라 두고 휠 목록도 그 연도가 들어가게 맞춘다.
        mutating func preselectYear(_ year: Int) {
            self.year = year
            yearOptions = YearOption.options(currentYear: currentYear, including: year)
        }

        /// 추천 대회로 바꾼 연도를 되돌린다.
        mutating func restoreYearBeforeSuggestion() {
            guard let saved = yearBeforeSuggestion else { return }
            yearBeforeSuggestion = nil
            preselectYear(saved.year)
        }

        /// 이미 저장한 대회에 부문을 더한다(프로필에서 진입).
        /// 저장해 둔 기록을 이번 흐름의 기록으로 넣어 두면 '부문 추가' 흐름(메달 → 부문)이 되고,
        /// 완료 화면에는 이 대회의 기존 부문까지 한 줄씩 보인다.
        public init(addingDivisionTo entries: [Competition], currentBelt: BeltRank? = nil) {
            self.init(mode: .add, currentBelt: currentBelt)
            guard let last = entries.last else { return }
            self.savedRecords = entries
            self.name = last.competitionName
            self.preselectYear(last.competitionYear)
            // 같은 대회의 다른 부문은 보통 같은 복장·같은 띠라 마지막 기록을 따른다.
            self.uniform = last.competitionUniform ?? .gi
            self.belt = last.competitionBelt ?? currentBelt
        }
    }

    // 기록하는 이유(메달)를 먼저 보여 주려고 결과부터 묻는다.
    // 대회명을 연도보다 먼저 물어, 공개 일정의 대회를 고르면 연도 단계에 그 연도를 골라 둔다(#126).
    // 진행 막대는 State.inputSteps 기준이라 '부문 추가'처럼 단계를 건너뛰는 흐름에서도 칸 수가 맞는다.
    struct YearBeforeSuggestion: Equatable, Sendable {
        let year: Int
        let pickedName: String
    }

    public enum Step: Equatable, Sendable {
        case result
        case name
        case year
        case division
        /// 저장 후 완료 화면 — 새 기록에서만 거친다(수정은 저장 후 바로 닫는다).
        case done
    }

    /// 부모(MyProfileFeature)가 저장을 마치고 돌려주는 결과.
    /// 저장은 프로필 전체를 다루는 부모가 하므로, 완료 화면은 저장이 성공한 뒤에만 보여 준다.
    public enum SaveResult: Sendable {
        case succeeded(Competition)
        case failed
    }

    /// 연도 단계 선택지 — 올해부터 1990년까지 최신순.
    ///
    /// 오래 수련한 사람은 옛 대회도 정확한 연도로 남기고 싶어 하므로 묶음('이전') 없이 연도를 전부 늘어놓는다.
    /// 휠은 올해에 맞춰 열리므로 최근 대회는 바로 넘어가고, 목록이 길어져도 휠 크기는 그대로다.
    /// 수정 중인 기록의 연도가 범위 밖이면 그 연도도 목록에 넣어 원래 값이 사라지지 않게 한다.
    public struct YearOption: Hashable, Identifiable, Sendable {
        let year: Int

        static let earliestYear = 1990

        public var id: Int { year }

        var displayText: String { "\(year)년" }

        static func options(currentYear: Int, including selectedYear: Int) -> [YearOption] {
            let upper = max(currentYear, selectedYear)
            let lower = min(earliestYear, selectedYear)
            return stride(from: upper, through: lower, by: -1).map(YearOption.init)
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case saveFinished(SaveResult)

        public enum ViewAction: Sendable {
            case backButtonTapped
            case nextButtonTapped
            case cancelButtonTapped
            case deleteButtonTapped
            case yearOptionSelected(YearOption)
            case resultSelected(CompetitionRank)
            case suggestionTapped(RegisteredCompetition)
            case namelessButtonTapped
            case uniformSelected(CompetitionUniform)
            case weightBoundToggled
            case absoluteToggled
            case beltSelected(BeltRank)
            case beltRowTapped
            case skipButtonTapped
            case addDivisionButtonTapped
            case doneButtonTapped
            case toastSwiped
        }

        public enum InternalAction: Sendable {
            case suggestionsLoaded([RegisteredCompetition])
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            case didFinishAdding(Competition)
            case didFinishEditing(original: Competition, updated: Competition)
            case didDelete(Competition)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    @Dependency(\.competitionClient) var competitionClient

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .view(.nextButtonTapped):
                guard !state.isSaving else { return .none }
                switch state.step {
                case .result:
                    state.step = state.isAddingDivision ? .division : .name
                    return .none
                case .name:
                    // 빈 값(공백 포함)일 때 다음 버튼은 View에서 비활성화되지만,
                    // 키보드 Return 등으로 빈 대회명으로 넘어가지 않도록 방어적으로 한 번 더 막는다.
                    guard !state.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return .none
                    }
                    state.step = .year
                    return .none
                case .year:
                    // 골라 둔 연도를 보고 넘어갔으니 받아들인 것으로 본다. 뒤로 가 대회명을 고쳐도 되돌리지 않는다.
                    state.yearBeforeSuggestion = nil
                    state.step = .division
                    return .none
                case .division:
                    return save(&state, uniform: state.uniform, belt: state.belt)
                case .done:
                    return .none
                }

            case .view(.skipButtonTapped):
                guard state.step == .division, !state.isSaving else { return .none }
                // 미리 채워 둔 도복·띠는 본인이 고른 값이 아니라 버리고, 직접 누른 칩만 남긴다.
                // 체급·앱솔루트는 미리 채우지 않으므로 입력했으면 저장한다.
                return save(
                    &state,
                    uniform: state.didPickUniform ? state.uniform : nil,
                    belt: state.didPickBelt ? state.belt : nil
                )

            case .view(.addDivisionButtonTapped):
                // 같은 대회의 다른 부문은 보통 같은 복장·같은 띠라 그대로 두고, 체급과 메달만 다시 고르게 한다.
                state.step = .result
                state.result = .gold
                state.weightText = ""
                state.weightBound = .under
                state.isAbsolute = false
                return .none

            case .view(.doneButtonTapped):
                return .run { _ in await self.dismiss() }

            case let .saveFinished(.succeeded(competition)):
                state.isSaving = false
                state.savedRecords.append(competition)
                state.hasSavedInThisFlow = true
                state.celebratesOnDone = true
                state.step = .done
                return .none

            case .saveFinished(.failed):
                // 입력한 값은 그대로 두어 같은 화면에서 다시 저장할 수 있게 한다.
                state.isSaving = false
                return showToast(&state, message: "저장에 실패했어요. 다시 시도해주세요")

            case .view(.toastSwiped), .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)

            case .view(.backButtonTapped):
                guard !state.isSaving else { return .none }
                switch state.step {
                case .result:
                    // 이번 흐름에서 저장한 뒤 부문 추가 중이면 그 완료 화면으로 돌아간다.
                    if state.hasSavedInThisFlow {
                        state.step = .done
                        state.celebratesOnDone = false
                        return .none
                    }
                    return .run { _ in await self.dismiss() }
                case .name:
                    state.step = .result
                    return .none
                case .year:
                    state.step = .name
                    return .none
                case .division:
                    state.step = state.isAddingDivision ? .result : .year
                    return .none
                case .done:
                    return .run { _ in await self.dismiss() }
                }

            case .view(.cancelButtonTapped):
                // 입력 중단: 스텝과 무관하게 플로우 전체를 종료한다. 이미 저장한 기록은 그대로 남는다.
                guard !state.isSaving else { return .none }
                return .run { _ in await self.dismiss() }

            case .view(.deleteButtonTapped):
                guard case let .edit(original) = state.mode else { return .none }
                return .send(.delegate(.didDelete(original)))

            case let .view(.yearOptionSelected(option)):
                // 직접 고른 연도라 목록은 그대로 둔다(굴리는 중에 목록이 바뀌면 칸이 밀린다).
                state.year = option.year
                state.yearBeforeSuggestion = nil
                return .none

            case let .view(.resultSelected(rank)):
                state.result = rank
                return .none

            case let .view(.uniformSelected(uniform)):
                // 두 칸짜리 선택이라 다시 눌러도 풀지 않는다 — 풀리면 화면에 보이는 것과 저장 값이 어긋난다.
                state.uniform = uniform
                state.didPickUniform = true
                return .none

            case .view(.weightBoundToggled):
                state.weightBound = state.weightBound == .under ? .over : .under
                return .none

            case .view(.absoluteToggled):
                state.isAbsolute.toggle()
                return .none

            case let .view(.beltSelected(belt)):
                state.belt = state.belt == belt ? nil : belt
                state.didPickBelt = true
                // 고르면 바로 접어 체급 화면으로 돌아간다.
                state.isBeltExpanded = false
                return .none

            case .view(.beltRowTapped):
                state.isBeltExpanded.toggle()
                return .none

            case .binding(\.weightText):
                // 숫자와 소수점 한 자리까지만 받는다(예: 76, 76.5, 100.5). 붙여넣기나 쉼표 입력도 같은 모양으로 맞춘다.
                let sanitized = Self.sanitizedWeightText(state.weightText)
                if sanitized != state.weightText {
                    state.weightText = sanitized
                }
                return .none

            case .binding(\.name):
                if let saved = state.yearBeforeSuggestion, state.name != saved.pickedName {
                    state.restoreYearBeforeSuggestion()
                }
                let keyword = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !keyword.isEmpty else {
                    state.suggestions = []
                    return .cancel(id: CancelID.searchCompetitions)
                }
                return .run { [clock, competitionClient] send in
                    try await clock.sleep(for: Self.searchDebounce)
                    do {
                        let suggestions = try await competitionClient.searchCompetitions(keyword)
                        await send(.internal(.suggestionsLoaded(suggestions)))
                    } catch is CancellationError {
                        return
                    } catch {
                        // 검색 API가 아직 없거나(backend #165) 실패해도 직접 입력으로 진행할 수 있으니 조용히 목록만 비운다.
                        Log.trace("대회 검색 실패: \(error)", category: .network, level: .info)
                        await send(.internal(.suggestionsLoaded([])))
                    }
                }
                .cancellable(id: CancelID.searchCompetitions, cancelInFlight: true)

            case .view(.namelessButtonTapped):
                guard state.step == .name, !state.isSaving else { return .none }
                // 기억 안 난다고 했으니 치다 만 글자는 대회명으로 남기지 않는다.
                state.name = ""
                state.suggestions = []
                state.restoreYearBeforeSuggestion()
                state.step = .year
                return .cancel(id: CancelID.searchCompetitions)

            case let .view(.suggestionTapped(competition)):
                state.name = competition.name
                state.suggestions = []
                // 고르기 직전 입력으로 시작된 검색이 늦게 돌아와 목록을 다시 띄우지 않게 한다.
                let cancelSearch: Effect<Action> = .cancel(id: CancelID.searchCompetitions)
                // 공개 일정에서 온 대회는 열린 연도를 알므로, 다음 연도 단계에 그 연도를 골라 둔다(#126).
                // 단계를 건너뛰지 않고 골라 둔 연도를 한 번 보여 주므로 따로 알리지 않는다.
                // 연도를 모르는 대회를 고르면 앞서 다른 추천으로 바꾼 연도도 되돌린다.
                state.restoreYearBeforeSuggestion()
                if let scheduledYear = competition.year {
                    state.yearBeforeSuggestion = YearBeforeSuggestion(year: state.year, pickedName: competition.name)
                    state.preselectYear(scheduledYear)
                }
                return cancelSearch

            case let .internal(.suggestionsLoaded(suggestions)):
                // 입력한 말로 시작하는 이름을 먼저 둔다(띄어쓰기 무시). 그 안의 순서는 서버가 준 대로 둔다.
                let key = state.name.competitionSearchKey
                let startsWithKey = suggestions.filter { $0.name.competitionSearchKey.hasPrefix(key) }
                let others = suggestions.filter { !$0.name.competitionSearchKey.hasPrefix(key) }
                state.suggestions = startsWithKey + others
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }

    // MARK: - Helpers

    /// 체급 입력을 "정수 3자리 + 소수 1자리"까지로 다듬는다. 쉼표는 소수점으로 본다.
    static func sanitizedWeightText(_ text: String) -> String {
        var integerPart = ""
        var fractionPart: String?
        for character in text.replacingOccurrences(of: ",", with: ".") {
            if character == "." {
                // ".5"처럼 소수점부터 치면 "0.5"로 읽는다(5로 바뀌지 않게).
                if fractionPart == nil {
                    if integerPart.isEmpty { integerPart = "0" }
                    fractionPart = ""
                }
            } else if character.isASCII, character.isNumber {
                if var fraction = fractionPart {
                    if fraction.isEmpty { fraction.append(character) }
                    fractionPart = fraction
                } else if integerPart.count < 3 {
                    integerPart.append(character)
                }
            }
        }
        guard let fractionPart else { return integerPart }
        return integerPart + "." + fractionPart
    }

    /// 이 화면 안에서 토스트를 띄운다. 이 화면이 MY 화면 위에 push돼 있어 MY 화면 토스트는 가려지기 때문이다.
    private func showToast(_ state: inout State, message: String) -> Effect<Action> {
        let toast = ToastState(message: message, style: .info)
        state.toast = toast
        return .run { [clock] send in
            try await clock.sleep(for: toast.duration)
            await send(.internal(.toastDismissed))
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }

    /// 입력한 값으로 기록을 만들어 부모에게 저장을 맡긴다.
    /// 새 기록은 부모가 저장 결과를 saveFinished로 돌려줄 때까지 기다렸다가 완료 화면으로 간다.
    /// - Parameters:
    ///   - uniform: 저장할 도복/노기. '건너뛰기'면 직접 고른 경우에만 넘긴다.
    ///   - belt: 저장할 출전 띠. '건너뛰기'면 직접 고른 경우에만 넘긴다.
    private func save(_ state: inout State, uniform: CompetitionUniform?, belt: BeltRank?) -> Effect<Action> {
        // 새 기록은 월 없이 저장하고, 월이 있던 기존 기록은 수정해도 원래 월·고정 여부를 유지한다.
        let original: Competition? = if case let .edit(original) = state.mode { original } else { nil }
        let competition = Competition(
            competitionYear: state.year,
            competitionMonth: original?.competitionMonth,
            competitionName: state.name,
            competitionRank: state.result,
            competitionUniform: uniform,
            competitionWeightLimit: state.weightLimit,
            competitionAbsolute: state.isAbsolute,
            competitionBelt: belt,
            isPinned: original?.isPinned ?? false
        )
        switch state.mode {
        case .add:
            state.isSaving = true
            return .send(.delegate(.didFinishAdding(competition)))
        case let .edit(original):
            return .send(.delegate(.didFinishEditing(original: original, updated: competition)))
        }
    }
}
