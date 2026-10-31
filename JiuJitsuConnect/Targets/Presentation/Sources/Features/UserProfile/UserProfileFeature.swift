//
//  UserProfileFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit

/// 남이 보는 프로필 — 커뮤니티에서 작성자를 누르면 열린다(#116).
///
/// 순서는 사진·닉네임·도장 → 벨트(+관장·사범 인증) → 대회 기록 → 최애 기술.
/// 띠·인증 여부가 상대를 판단하는 첫 기준이라 맨 위에 두고, 체급은 보여 주지 않는다.
@Reducer
public struct UserProfileFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        case fetch
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        let userId: Int
        var profile: CommunityPublicProfile?
        var isLoading = false
        var hasError = false
        /// 탈퇴 유예 중인 회원의 글·댓글은 남아 있어 작성자를 눌러도 없는 회원일 수 있다.
        var isNotFoundAlertPresented = false

        public init(userId: Int) {
            self.userId = userId
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
            case backTapped
            case notFoundAlertConfirmed
        }

        public enum InternalAction: Sendable {
            case profileResponse(TaskResult<CommunityPublicProfile>)
        }
    }

    @Dependency(\.communityClient) var communityClient
    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 위에 쌓인 화면에서 돌아올 때 다시 부르지 않는다
                guard state.profile == nil, !state.isLoading else { return .none }
                return fetch(&state)

            case .view(.retryTapped):
                return fetch(&state)

            case .view(.backTapped):
                return .run { _ in await self.dismiss() }

            case .view(.notFoundAlertConfirmed):
                // 확인 버튼과 알럿 닫힘이 함께 들어와도 한 번만 닫는다
                guard state.isNotFoundAlertPresented else { return .none }
                state.isNotFoundAlertPresented = false
                return .run { _ in await self.dismiss() }

            case let .internal(.profileResponse(.success(profile))):
                state.isLoading = false
                state.profile = profile
                return .none

            case let .internal(.profileResponse(.failure(error))):
                state.isLoading = false
                if case .apiError(code: .userNotFound, _)? = error as? DomainError {
                    state.isNotFoundAlertPresented = true
                } else {
                    Log.trace("공개 프로필 조회 실패: userId=\(state.userId) \(error)", category: .network, level: .error)
                    state.hasError = true
                }
                return .none
            }
        }
    }

    private func fetch(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.hasError = false
        let userId = state.userId
        return .run { send in
            await send(.internal(.profileResponse(TaskResult {
                try await communityClient.fetchPublicProfile(userId)
            })))
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
}
