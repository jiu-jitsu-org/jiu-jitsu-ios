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
        var step: Step = .date

        // 1단계: 날짜 — 기본 선택 연도는 가장 최신(현재) 연도. 연도 Picker 상한과 일치한다.
        var year: Int = Calendar.current.component(.year, from: Date())
        var month: Int = 1

        // 2단계: 대회명 (TextField 직접 바인딩)
        // 대회명은 닉네임과 달리 중복을 허용하므로 별도 검증 없이 "빈 값" 여부만 본다.
        // 빈 값이면 다음 버튼을 비활성화하므로(View의 .disabled) 별도 검증 상태/문구는 두지 않는다.
        var name: String = ""

        // 3단계: 결과 — Picker UI 특성상 초기 선택값이 필요하므로 옵셔널이 아닌 기본값 사용
        var result: CompetitionRank = .gold

        public init() {}

        public init(mode: Mode) {
            self.mode = mode
            if case let .edit(original) = mode {
                self.year = original.competitionYear
                self.month = original.competitionMonth
                self.name = original.competitionName
                self.result = original.competitionRank
            }
        }
    }

    public enum Step: Equatable, Sendable {
        case date
        case name
        case result
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
            case yearSelected(Int)
            case monthSelected(Int)
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
                case .date:
                    state.step = .name
                    return .none
                case .name:
                    // 빈 값(공백 포함)일 때 다음 버튼은 View에서 비활성화되지만,
                    // 빈 대회명이 result 단계로 새지 않도록 방어적으로 한 번 더 막는다.
                    guard !state.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return .none
                    }
                    state.step = .result
                    return .none
                case .result:
                    let updated = Competition(
                        competitionYear: state.year,
                        competitionMonth: state.month,
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
                case .date:
                    return .run { _ in await self.dismiss() }
                case .name:
                    state.step = .date
                    return .none
                case .result:
                    state.step = .name
                    return .none
                }

            case .view(.cancelButtonTapped):
                // 입력 중단: 스텝과 무관하게 플로우 전체를 종료한다.
                return .run { _ in await self.dismiss() }

            case .view(.deleteButtonTapped):
                guard case let .edit(original) = state.mode else { return .none }
                return .send(.delegate(.didDelete(original)))

            case let .view(.yearSelected(year)):
                state.year = year
                return .none

            case let .view(.monthSelected(month)):
                state.month = month
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
