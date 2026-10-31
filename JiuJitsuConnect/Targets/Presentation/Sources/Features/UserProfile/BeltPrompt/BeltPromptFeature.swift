//
//  BeltPromptFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit

/// 띠 묻기 시트 — 띠가 없는 회원이 남의 프로필을 처음 볼 때 띠·그랄만 묻는다(#130).
///
/// 필수 입력 알럿 대신 활동하는 순간에 가볍게 묻는다(jiu-jitsu-frontend#270). 체급은 공개를 망설이는
/// 정보라 묻지 않는다. 웹은 글·댓글 등록 직후에 같은 시트를 띄운다(jiu-jitsu-frontend#283).
@Reducer
public struct BeltPromptFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        /// 저장할 때 띠만 바꿔 보낼 내 프로필
        let myProfile: CommunityProfile
        var selectedRank: BeltRank = .white
        var selectedStripe: BeltStripe = .none
        var isSaving = false
        var hasSaveError = false

        public init(myProfile: CommunityProfile) {
            self.myProfile = myProfile
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case rankSelected(BeltRank)
            case stripeSelected(BeltStripe)
            case saveTapped
            case laterTapped
        }

        public enum InternalAction: Sendable {
            case saveResponse(TaskResult<CommunityProfile>)
        }

        public enum DelegateAction: Sendable {
            case saved(CommunityProfile)
            /// '나중에' — 부모가 7일 동안 띄우지 않게 기록하고 닫는다
            case later
        }
    }

    @Dependency(\.communityClient) var communityClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.rankSelected(rank)):
                state.selectedRank = rank
                return .none

            case let .view(.stripeSelected(stripe)):
                state.selectedStripe = stripe
                return .none

            case .view(.saveTapped):
                guard !state.isSaving else { return .none }
                state.isSaving = true
                state.hasSaveError = false
                // BELT 저장은 띠·그랄만 바꾸고 성별·체급은 서버 값을 그대로 둔다(jiu-jitsu-backend#172)
                let profile = state.myProfile.updatingBelt(rank: state.selectedRank, stripe: state.selectedStripe)
                return .run { send in
                    await send(.internal(.saveResponse(TaskResult {
                        try await communityClient.updateProfile(profile, .belt)
                    })))
                }

            case .view(.laterTapped):
                guard !state.isSaving else { return .none }
                return .send(.delegate(.later))

            case let .internal(.saveResponse(.success(profile))):
                state.isSaving = false
                return .send(.delegate(.saved(profile)))

            case let .internal(.saveResponse(.failure(error))):
                // 시트를 닫지 않고 다시 누를 수 있게 둔다
                Log.trace("띠 저장 실패: \(error)", category: .network, level: .error)
                state.isSaving = false
                state.hasSaveError = true
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
