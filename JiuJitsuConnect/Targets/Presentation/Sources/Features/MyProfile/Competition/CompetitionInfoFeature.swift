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

    @ObservableState
    public struct State: Equatable, Sendable {
        var step: Step = .date

        // 1단계: 날짜
        var year: Int = 2025
        var month: Int = 1

        // 2단계: 대회명 (TextField 직접 바인딩)
        var name: String = ""

        // 3단계: 결과
        var result: CompetitionRank? = nil

        public init() {}
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
            case yearSelected(Int)
            case monthSelected(Int)
            case resultSelected(CompetitionRank)
        }

        public enum DelegateAction: Sendable {
            case didFinish(Competition)
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
                    state.step = .result
                    return .none
                case .result:
                    guard let rank = state.result else { return .none }
                    let competition = Competition(
                        competitionYear: state.year,
                        competitionMonth: state.month,
                        competitionName: state.name,
                        competitionRank: rank
                    )
                    return .send(.delegate(.didFinish(competition)))
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
