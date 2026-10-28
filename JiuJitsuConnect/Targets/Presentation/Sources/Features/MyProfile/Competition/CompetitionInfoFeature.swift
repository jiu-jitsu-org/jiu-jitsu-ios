//
//  CompetitionInfoFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import CoreKit
import Domain

@Reducer
public struct CompetitionInfoFeature: Sendable {

    private enum CancelID {
        case searchCompetitions
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

        // 1단계: 결과 — Picker UI 특성상 초기 선택값이 필요하므로 옵셔널이 아닌 기본값 사용
        var result: CompetitionRank = .gold

        // 2단계: 연도 — 몇 월이었는지는 기억이 가장 흐려 입력이 막히므로 연도만 받는다.
        // 기본 선택은 올해. '이전'을 고르면 year에는 경계 연도(올해 - 5) 이하 값이 들어간다(YearOption 참고).
        let currentYear: Int = Calendar.current.component(.year, from: Date())
        var year: Int = Calendar.current.component(.year, from: Date())

        // 3단계: 대회명 (TextField 직접 바인딩)
        // 대회명은 닉네임과 달리 중복을 허용하므로 별도 검증 없이 "빈 값" 여부만 본다.
        // 빈 값이면 완료 버튼을 비활성화하므로(View의 .disabled) 별도 검증 상태/문구는 두지 않는다.
        var name: String = ""

        // 입력한 대회명과 맞는 등록된 대회 목록. 고르면 이름이 채워지고, 없으면 직접 입력한 이름을 그대로 쓴다.
        var suggestions: [RegisteredCompetition] = []

        // 4단계: 출전 부문 — 건너뛸 수 있고, 고른 칩을 다시 누르면 선택이 풀린다.
        // 도복 대회가 더 흔해 새 기록은 도복으로, 출전 띠는 지금 띠로 미리 골라 둔다(대부분 그대로 '완료'만 누르게).
        var uniform: CompetitionUniform? = .gi
        var weightClass: CompetitionWeightClass?
        var belt: BeltRank?

        public init() {}

        /// - Parameter currentBelt: 지금 프로필 띠. 새 기록의 출전 띠 기본값으로 쓴다.
        public init(mode: Mode, currentBelt: BeltRank? = nil) {
            self.mode = mode
            switch mode {
            case .add:
                self.belt = currentBelt
            case let .edit(original):
                self.year = original.competitionYear
                self.name = original.competitionName
                self.result = original.competitionRank
                // 수정은 저장된 값을 그대로 보여 준다. 부문 없이 저장된 기록에 기본값을 채우면
                // 이름만 고치려던 사람이 모르는 사이 부문까지 저장하게 되므로 비워 둔다.
                self.uniform = original.competitionUniform
                self.weightClass = original.competitionWeightClass
                self.belt = original.competitionBelt
            }
        }
    }

    // 기록하는 이유(메달)를 먼저 보여 주려고 결과부터 묻는다.
    // rawValue를 진행 막대 위치로 쓰므로, 단계를 추가할 때는 화면 순서대로 선언한다.
    public enum Step: Int, CaseIterable, Equatable, Sendable {
        case result
        case year
        case name
        case division

        static let progressSegmentCount = allCases.count
    }

    /// 연도 단계 선택지 — 올해부터 최근 5년 + '이전'.
    ///
    /// 오래된 대회일수록 정확한 연도도 흐려서 5년보다 이전은 하나로 묶는다.
    /// 서버는 연도를 정수로만 받으므로 '이전'은 경계 연도(올해 - 5) 이하 값으로 저장한다.
    /// 수정 모드에서 경계 이하 연도는 '이전'으로 보이고, 다른 연도를 고르지 않으면 원래 연도를 그대로 둔다.
    public enum YearOption: Hashable, Identifiable, Sendable {
        case year(Int)
        case earlier

        static let recentYearCount = 5

        public var id: Self { self }

        var displayText: String {
            switch self {
            case let .year(year): return "\(year)년"
            case .earlier: return "이전"
            }
        }

        static func options(currentYear: Int) -> [YearOption] {
            (0..<recentYearCount).map { .year(currentYear - $0) } + [.earlier]
        }

        static func earliestRecentYear(currentYear: Int) -> Int {
            currentYear - (recentYearCount - 1)
        }

        init(year: Int, currentYear: Int) {
            self = year < Self.earliestRecentYear(currentYear: currentYear) ? .earlier : .year(year)
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case backButtonTapped
            case nextButtonTapped
            case cancelButtonTapped
            case deleteButtonTapped
            case yearOptionSelected(YearOption)
            case resultSelected(CompetitionRank)
            case suggestionTapped(RegisteredCompetition)
            case uniformSelected(CompetitionUniform)
            case weightClassSelected(CompetitionWeightClass)
            case beltSelected(BeltRank)
            case skipButtonTapped
        }

        public enum InternalAction: Sendable {
            case suggestionsLoaded([RegisteredCompetition])
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
                switch state.step {
                case .result:
                    state.step = .year
                    return .none
                case .year:
                    state.step = .name
                    return .none
                case .name:
                    // 빈 값(공백 포함)일 때 다음 버튼은 View에서 비활성화되지만,
                    // 키보드 Return 등으로 빈 대회명으로 넘어가지 않도록 방어적으로 한 번 더 막는다.
                    guard !state.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return .none
                    }
                    state.step = .division
                    return .none
                case .division:
                    return save(state, includingDivision: true)
                }

            case .view(.skipButtonTapped):
                guard state.step == .division else { return .none }
                return save(state, includingDivision: false)

            case .view(.backButtonTapped):
                switch state.step {
                case .result:
                    return .run { _ in await self.dismiss() }
                case .year:
                    state.step = .result
                    return .none
                case .name:
                    state.step = .year
                    return .none
                case .division:
                    state.step = .name
                    return .none
                }

            case .view(.cancelButtonTapped):
                // 입력 중단: 스텝과 무관하게 플로우 전체를 종료한다.
                return .run { _ in await self.dismiss() }

            case .view(.deleteButtonTapped):
                guard case let .edit(original) = state.mode else { return .none }
                return .send(.delegate(.didDelete(original)))

            case let .view(.yearOptionSelected(option)):
                switch option {
                case let .year(year):
                    state.year = year
                case .earlier:
                    // 이미 '이전'에 해당하는 연도(수정 중인 오래된 기록)면 원래 연도를 지킨다.
                    let boundary = YearOption.earliestRecentYear(currentYear: state.currentYear) - 1
                    state.year = min(state.year, boundary)
                }
                return .none

            case let .view(.resultSelected(rank)):
                state.result = rank
                return .none

            case let .view(.uniformSelected(uniform)):
                state.uniform = state.uniform == uniform ? nil : uniform
                return .none

            case let .view(.weightClassSelected(weightClass)):
                state.weightClass = state.weightClass == weightClass ? nil : weightClass
                return .none

            case let .view(.beltSelected(belt)):
                state.belt = state.belt == belt ? nil : belt
                return .none

            case .binding(\.name):
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

            case let .view(.suggestionTapped(competition)):
                state.name = competition.name
                state.suggestions = []
                // 고르기 직전 입력으로 시작된 검색이 늦게 돌아와 목록을 다시 띄우지 않게 한다.
                return .cancel(id: CancelID.searchCompetitions)

            case let .internal(.suggestionsLoaded(suggestions)):
                state.suggestions = suggestions
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }

    // MARK: - Helpers

    /// 입력한 값으로 기록을 만들어 부모에게 저장을 맡긴다.
    /// - Parameter includingDivision: '건너뛰기'면 false — 미리 골라 둔 도복·띠도 저장하지 않는다.
    private func save(_ state: State, includingDivision: Bool) -> Effect<Action> {
        // 새 기록은 월 없이 저장하고, 월이 있던 기존 기록은 수정해도 원래 월을 유지한다.
        let originalMonth: Int? = if case let .edit(original) = state.mode {
            original.competitionMonth
        } else {
            nil
        }
        let competition = Competition(
            competitionYear: state.year,
            competitionMonth: originalMonth,
            competitionName: state.name,
            competitionRank: state.result,
            competitionUniform: includingDivision ? state.uniform : nil,
            competitionWeightClass: includingDivision ? state.weightClass : nil,
            competitionBelt: includingDivision ? state.belt : nil
        )
        switch state.mode {
        case .add:
            return .send(.delegate(.didFinishAdding(competition)))
        case let .edit(original):
            return .send(.delegate(.didFinishEditing(original: original, updated: competition)))
        }
    }
}
