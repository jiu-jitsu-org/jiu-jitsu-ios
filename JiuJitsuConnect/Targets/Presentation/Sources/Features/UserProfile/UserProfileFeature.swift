//
//  UserProfileFeature.swift
//  Presentation
//

import Foundation
import ComposableArchitecture
import Domain
import CoreKit
import DesignSystem

/// 남이 보는 프로필 — 커뮤니티에서 작성자를 누르면 열린다(#116).
///
/// 순서는 사진·닉네임·도장 → 벨트(+관장·사범 인증) → 대회 기록 → 최애 기술.
/// 띠·인증 여부가 상대를 판단하는 첫 기준이라 맨 위에 두고, 체급은 보여 주지 않는다.
@Reducer
public struct UserProfileFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        case fetch
        case toast
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        let userId: Int
        var profile: CommunityPublicProfile?
        var isLoading = false
        var hasError = false
        /// 탈퇴 유예 중인 회원의 글·댓글은 남아 있어 작성자를 눌러도 없는 회원일 수 있다.
        var isNotFoundAlertPresented = false

        /// 보는 사람이 로그인했는지 — 게스트에게는 띠를 묻지 않는다(저장할 프로필이 없음)
        let canPromptBelt: Bool
        /// 이 화면을 연 동안 한 번만 확인한다
        var hasCheckedBeltPrompt = false
        @Presents var beltPrompt: BeltPromptFeature.State?
        var toast: ToastState?

        public init(userId: Int, canPromptBelt: Bool = true) {
            self.userId = userId
            self.canPromptBelt = canPromptBelt
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case beltPrompt(PresentationAction<BeltPromptFeature.Action>)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
            case backTapped
            case notFoundAlertConfirmed
            case toastDismissed
        }

        public enum InternalAction: Sendable {
            case profileResponse(TaskResult<CommunityPublicProfile>)
            /// 띠 묻기 확인 — 내 프로필의 띠가 비었는지 본다(#130)
            case myProfileResponse(TaskResult<CommunityProfile>)
            case showToast(ToastState)
        }
    }

    @Dependency(\.communityClient) var communityClient
    @Dependency(\.beltPromptClient) var beltPromptClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
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
                return checkBeltPrompt(&state)

            case let .internal(.profileResponse(.failure(error))):
                state.isLoading = false
                if case .apiError(code: .userNotFound, _)? = error as? DomainError {
                    state.isNotFoundAlertPresented = true
                } else {
                    Log.trace("공개 프로필 조회 실패: userId=\(state.userId) \(error)", category: .network, level: .error)
                    state.hasError = true
                }
                return .none

            // MARK: - 띠 묻기 (#130)

            case let .internal(.myProfileResponse(.success(myProfile))):
                guard myProfile.beltRank == nil else { return .none }
                state.beltPrompt = BeltPromptFeature.State(myProfile: myProfile)
                return .none

            case let .internal(.myProfileResponse(.failure(error))):
                // 묻지 못해도 프로필 보기는 그대로 — 다음 날 다시 확인한다
                Log.trace("띠 묻기 확인 실패: \(error)", category: .network, level: .error)
                return .none

            case .beltPrompt(.presented(.delegate(.saved))):
                state.beltPrompt = nil
                return .send(.internal(.showToast(.init(message: "벨트를 저장했어요", style: .info))))

            case .beltPrompt(.presented(.delegate(.later))):
                state.beltPrompt = nil
                beltPromptClient.snooze(now)
                return .none

            // 바깥을 눌러 닫은 것도 '나중에'와 같다(웹과 같은 규칙)
            case .beltPrompt(.dismiss):
                beltPromptClient.snooze(now)
                return .none

            case .beltPrompt:
                return .none

            case let .internal(.showToast(toast)):
                state.toast = toast
                return .run { send in
                    try await clock.sleep(for: toast.duration)
                    await send(.view(.toastDismissed), animation: .default)
                }
                .cancellable(id: CancelID.toast, cancelInFlight: true)

            case .view(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
            }
        }
        .ifLet(\.$beltPrompt, action: \.beltPrompt) {
            BeltPromptFeature()
        }
    }

    /// 띠가 없는 회원이면 띠 묻기 시트를 띄운다. 하루 한 번까지만 확인하고, 띠가 있는지 서버에
    /// 묻는 것도 그날의 한 번으로 친다(띠가 있는 회원이 프로필을 볼 때마다 조회하지 않게).
    private func checkBeltPrompt(_ state: inout State) -> Effect<Action> {
        guard state.canPromptBelt, !state.hasCheckedBeltPrompt else { return .none }
        state.hasCheckedBeltPrompt = true
        guard beltPromptClient.canCheck(now) else { return .none }
        beltPromptClient.markChecked(now)
        return .run { send in
            await send(.internal(.myProfileResponse(TaskResult {
                try await communityClient.fetchProfile()
            })))
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
