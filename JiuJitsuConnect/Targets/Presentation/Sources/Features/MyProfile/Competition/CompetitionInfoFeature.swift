//
//  CompetitionInfoFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct CompetitionInfoFeature: Sendable {

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
        // 기본 선택은 올해.
        let currentYear: Int = Calendar.current.component(.year, from: Date())
        var year: Int = Calendar.current.component(.year, from: Date())

        // 3단계: 대회명 (TextField 직접 바인딩)
        // 대회명은 닉네임과 달리 중복을 허용하므로 별도 검증 없이 "빈 값" 여부만 본다.
        // 빈 값이면 완료 버튼을 비활성화하므로(View의 .disabled) 별도 검증 상태/문구는 두지 않는다.
        var name: String = ""

        public init() {}

        public init(mode: Mode) {
            self.mode = mode
            if case let .edit(original) = mode {
                self.year = original.competitionYear
                self.name = original.competitionName
                self.result = original.competitionRank
            }
        }
    }

    // 기록하는 이유(메달)를 먼저 보여 주려고 결과부터 묻는다.
    // rawValue를 진행 막대 위치로 쓰므로, 단계를 추가할 때는 화면 순서대로 선언한다.
    public enum Step: Int, CaseIterable, Equatable, Sendable {
        case result
        case year
        case name

        // 진행 막대는 출전 부문 단계(#122)까지 포함한 4칸으로 보여 준다.
        // 부문 단계가 생기기 전까지는 대회명 단계에서 저장하므로 마지막 칸은 빈 채로 끝난다.
        // 부문 단계를 추가하면 allCases.count로 바꾼다.
        static let progressSegmentCount = 4
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
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case backButtonTapped
            case nextButtonTapped
            case cancelButtonTapped
            case deleteButtonTapped
            case yearOptionSelected(YearOption)
            case resultSelected(CompetitionRank)
        }

        public enum DelegateAction: Sendable {
            case didFinishAdding(Competition)
            case didFinishEditing(original: Competition, updated: Competition)
            case didDelete(Competition)
        }
    }

    @Dependency(\.dismiss) var dismiss

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
                    // 빈 값(공백 포함)일 때 완료 버튼은 View에서 비활성화되지만,
                    // 키보드 Return 등으로 빈 대회명이 저장되지 않도록 방어적으로 한 번 더 막는다.
                    guard !state.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return .none
                    }
                    // 새 기록은 월 없이 저장하고, 월이 있던 기존 기록은 수정해도 원래 월을 유지한다.
                    let originalMonth: Int? = if case let .edit(original) = state.mode {
                        original.competitionMonth
                    } else {
                        nil
                    }
                    let updated = Competition(
                        competitionYear: state.year,
                        competitionMonth: originalMonth,
                        competitionName: state.name,
                        competitionRank: state.result
                    )
                    switch state.mode {
                    case .add:
                        return .send(.delegate(.didFinishAdding(updated)))
                    case let .edit(original):
                        return .send(.delegate(.didFinishEditing(original: original, updated: updated)))
                    }
                }

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
                }

            case .view(.cancelButtonTapped):
                // 입력 중단: 스텝과 무관하게 플로우 전체를 종료한다.
                return .run { _ in await self.dismiss() }

            case .view(.deleteButtonTapped):
                guard case let .edit(original) = state.mode else { return .none }
                return .send(.delegate(.didDelete(original)))

            case let .view(.yearOptionSelected(option)):
                state.year = option.year
                return .none

            case let .view(.resultSelected(rank)):
                state.result = rank
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }
}
