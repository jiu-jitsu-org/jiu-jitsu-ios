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
        case viewer
        case toast
    }

    /// ⋯ 메뉴에서 띄우는 확인 알럿. 웹 브릿지 알럿과 같은 표면(`webBridgeDialogs`)을 쓰므로 requestId로 구분한다.
    enum MenuDialog: String, Sendable {
        /// 차단하기 → 확인
        case block
        /// 신고 뒤 차단을 한 번 물음
        case blockAfterReport
    }

    /// 회원 신고 사유 — 웹 글 · 댓글 신고(`REPORT_REASONS`, jiu-jitsu-frontend#514)와 순서 · 문구 · 코드를 같게 둔다.
    static let reportReasons: [SelectSheetPayload.Option] = [
        .init(value: "ABUSE", label: "욕설 및 비방", allowsCustomText: false),
        .init(value: "SPAM", label: "광고 및 홍보", allowsCustomText: false),
        .init(value: "ADULT", label: "음란 또는 부적절한 콘텐츠", allowsCustomText: false),
        .init(value: "INCITEMENT", label: "분쟁유도", allowsCustomText: false),
        .init(value: "HARASSMENT", label: "혐오 및 괴롭힘", allowsCustomText: false),
        .init(value: "RIGHTS_VIOLATION", label: "개인정보 노출 및 권리 침해", allowsCustomText: false),
        .init(value: "ILLEGAL_FILMING", label: "불법촬영물", allowsCustomText: false),
        .init(value: "OTHER", label: "기타", allowsCustomText: true)
    ]

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

        // MARK: 신고 · 차단 (#328)

        /// 이 기기에 로그인 정보가 있는지 — 프로필을 연 곳(커뮤니티 · 대회 탭 · MY)이 넘긴 값이 아니라 실제 상태로 본다
        var isViewerLoggedIn = false
        /// 내 회원 번호. 웹이 내 이름을 남의 프로필로 여는 경로도 있어 직접 확인한다. 모르면 메뉴를 숨긴다
        var myUserId: Int?
        /// 내가 이 회원을 차단했는지. nil이면(서버가 아직 모름 · 비로그인) 차단 메뉴 없이 신고만
        var isBlocked: Bool?
        /// 신고 · 차단 요청 중 — ⋯를 다시 열 수 없게 한다(연타로 차단 → 해제가 되지 않게)
        var isMenuRequestInFlight = false
        var menuDialog: ConfirmDialogPayload?
        var reportSheet: SelectSheetPayload?

        var showsMenu: Bool {
            guard isViewerLoggedIn, let profile, let myUserId else { return false }
            return profile.userId != myUserId
        }

        public init(userId: Int, canPromptBelt: Bool = true) {
            self.userId = userId
            self.canPromptBelt = canPromptBelt
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case beltPrompt(PresentationAction<BeltPromptFeature.Action>)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
            case backTapped
            case notFoundAlertConfirmed
            case toastDismissed
            // ⋯ 메뉴 (#328)
            case reportMenuTapped
            case blockMenuTapped
            case unblockMenuTapped
            case menuDialogButtonTapped(ConfirmDialogOutcome)
            case menuDialogDismissed
            case reportSheetSubmitted(value: String, customText: String?)
            case reportSheetDismissed
        }

        public enum InternalAction: Sendable {
            case profileResponse(TaskResult<CommunityPublicProfile>)
            /// 띠 묻기 확인 — 내 프로필의 띠가 비었는지 본다(#130)
            case myProfileResponse(TaskResult<CommunityProfile>)
            /// ⋯ 메뉴를 보일지 — 내 회원 번호(#328)
            case viewerResponse(TaskResult<UserProfile>)
            /// 사유는 분석 기록(`report_submit`)에 싣는다 — 시트가 제출 때 닫혀 응답 시점엔 상태에 없다(#428)
            case reportResponse(reason: String, TaskResult<Void>)
            case blockResponse(afterReport: Bool, TaskResult<Bool>)
            case unblockResponse(TaskResult<Void>)
            case showToast(ToastState)
        }

        public enum DelegateAction: Sendable {
            /// 차단 · 해제가 서버에 반영됨 → 부모가 열린 웹뷰 모두에 USER_BLOCK_CHANGED를 보낸다(#328)
            case blockChanged(userId: Int, blocked: Bool)
        }
    }

    @Dependency(\.communityClient) var communityClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.beltPromptClient) var beltPromptClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.analyticsClient) var analyticsClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 위에 쌓인 화면에서 돌아올 때 다시 부르지 않는다
                guard state.profile == nil, !state.isLoading else { return .none }
                return .merge(fetch(&state), checkViewer(&state))

            case .view(.retryTapped):
                return .merge(fetch(&state), checkViewer(&state))

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
                state.isBlocked = profile.isBlocked
                return checkBeltPrompt(&state)

            case let .internal(.profileResponse(.failure(error))):
                state.isLoading = false
                if case .apiError(code: .userNotFound, _)? = error as? DomainError {
                    state.isNotFoundAlertPresented = true
                } else {
                    Log.trace("공개 프로필 조회 실패: userId=\(state.userId) \(error)", category: .network, level: .error)
                    state.hasError = true
                    analyticsClient.logErrorShown(error)
                }
                return .none

            // MARK: - 신고 · 차단 (#328)

            case let .internal(.viewerResponse(.success(viewer))):
                state.myUserId = viewer.userId
                return .none

            case let .internal(.viewerResponse(.failure(error))):
                // 내 프로필인지 모르면 ⋯를 숨긴다 — 내 계정을 신고 · 차단하는 메뉴가 보이는 것보다 낫다
                Log.trace("내 회원 번호 확인 실패: \(error)", category: .network, level: .error)
                return .none

            case .view(.reportMenuTapped):
                guard state.showsMenu, !state.isMenuRequestInFlight else { return .none }
                // 확인 알럿 없이 사유 시트로 바로 — 시트의 [신고하기]가 확인이다(웹 글 · 댓글 신고와 같음, jiu-jitsu-frontend#550)
                state.reportSheet = SelectSheetPayload(
                    requestId: "report-user",
                    title: "어떤 문제인가요?",
                    message: "신고는 익명으로 처리되며, 검토 후 조치돼요.",
                    options: Self.reportReasons,
                    customTextPlaceholder: "신고할 내용을 입력해주세요.",
                    customTextMaxLength: SelectSheetPayload.defaultCustomTextMaxLength,
                    submitText: "신고하기"
                )
                return .none

            case .view(.reportSheetDismissed):
                state.reportSheet = nil
                return .none

            case let .view(.reportSheetSubmitted(reason, customText)):
                // 제출과 딤 닫힘이 함께 들어와도 한 번만 보낸다
                guard state.reportSheet != nil, !state.isMenuRequestInFlight else { return .none }
                state.reportSheet = nil
                state.isMenuRequestInFlight = true
                let userId = state.userId
                // 자유 입력은 '기타'를 골라 입력했을 때만 싣는다
                let detail = customText?.trimmingCharacters(in: .whitespacesAndNewlines)
                return .run { send in
                    await send(.internal(.reportResponse(reason: reason, TaskResult {
                        try await communityClient.reportUser(userId, reason, detail?.isEmpty == false ? detail : nil)
                    })))
                }

            case .internal(.reportResponse(_, .success)):
                state.isMenuRequestInFlight = false
                // 차단 여부를 모르면(서버가 아직 내려 주지 않음) 차단을 묻지 않는다 — 지금 서버의 차단은 토글이라 이미 차단한 회원이면 풀린다
                guard state.isBlocked == false, let profile = state.profile else {
                    return showToast("회원을 신고했어요", status: .success)
                }
                state.menuDialog = ConfirmDialogPayload(
                    requestId: MenuDialog.blockAfterReport.rawValue,
                    title: "신고했어요",
                    message: "\(profile.nickname)님을 차단할까요? 차단하면 해당 유저의 글과 댓글이 보이지 않아요.",
                    confirmText: "차단",
                    cancelText: "괜찮아요",
                    destructive: true,
                    dismissOnOutsideTap: true
                )
                return .none

            case let .internal(.reportResponse(_, .failure(error))):
                state.isMenuRequestInFlight = false
                if case .apiError(code: .alreadyReported, _)? = error as? DomainError {
                    return showToast("이미 신고한 회원이에요", status: .info)
                }
                return showMenuFailure("회원을 신고하지 못했어요", error: error)

            case .view(.blockMenuTapped):
                guard state.showsMenu, !state.isMenuRequestInFlight, state.isBlocked == false, let profile = state.profile else { return .none }
                // 웹 댓글 ⋮ 차단과 같은 문구(use-block-member)
                state.menuDialog = ConfirmDialogPayload(
                    requestId: MenuDialog.block.rawValue,
                    title: "\(profile.nickname)님 차단",
                    titleParts: .init(truncatable: profile.nickname, suffix: "님 차단"),
                    message: "차단하면 해당 유저의 글과 댓글이 보이지 않아요.",
                    confirmText: "차단",
                    cancelText: nil,
                    destructive: true,
                    dismissOnOutsideTap: true
                )
                return .none

            case let .view(.menuDialogButtonTapped(outcome)):
                // 버튼과 알럿 닫힘이 함께 들어와도 한 번만 처리한다
                guard let dialog = state.menuDialog else { return .none }
                state.menuDialog = nil
                guard outcome == .confirm, !state.isMenuRequestInFlight else { return .none }
                state.isMenuRequestInFlight = true
                let userId = state.userId
                let afterReport = dialog.requestId == MenuDialog.blockAfterReport.rawValue
                return .run { send in
                    await send(.internal(.blockResponse(afterReport: afterReport, TaskResult {
                        try await communityClient.blockUser(userId)
                    })))
                }

            case .view(.menuDialogDismissed):
                state.menuDialog = nil
                return .none

            case let .internal(.blockResponse(afterReport, .success(isBlocked))):
                state.isMenuRequestInFlight = false
                // 결과가 차단일 때만 차단 완료로 안내한다(웹과 같음)
                guard isBlocked else {
                    return showToast("유저를 차단하지 못했어요", status: .error)
                }
                state.isBlocked = true
                return .merge(
                    showToast(afterReport ? "신고하고 차단했어요" : "유저를 차단했어요", status: .success),
                    .send(.delegate(.blockChanged(userId: state.userId, blocked: true)))
                )

            case let .internal(.blockResponse(_, .failure(error))):
                state.isMenuRequestInFlight = false
                return showMenuFailure("유저를 차단하지 못했어요", error: error)

            case .view(.unblockMenuTapped):
                guard state.showsMenu, !state.isMenuRequestInFlight, state.isBlocked == true else { return .none }
                state.isMenuRequestInFlight = true
                let userId = state.userId
                return .run { send in
                    await send(.internal(.unblockResponse(TaskResult {
                        try await communityClient.unblockUser(userId)
                    })))
                }

            case .internal(.unblockResponse(.success)):
                state.isMenuRequestInFlight = false
                state.isBlocked = false
                return .merge(
                    showToast("차단을 해제했어요", status: .success),
                    .send(.delegate(.blockChanged(userId: state.userId, blocked: false)))
                )

            case let .internal(.unblockResponse(.failure(error))):
                state.isMenuRequestInFlight = false
                return showMenuFailure("차단을 해제하지 못했어요", error: error)

            case .delegate:
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
                return .send(.internal(.showToast(.init(message: "벨트를 저장했어요", status: .success))))

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

    /// 로그인했으면 내 회원 번호를 받아 ⋯ 메뉴를 보일지 정한다(#328). 게스트는 메뉴가 없어 부르지 않는다.
    private func checkViewer(_ state: inout State) -> Effect<Action> {
        state.isViewerLoggedIn = authClient.hasValidToken()
        guard state.isViewerLoggedIn, state.myUserId == nil else { return .none }
        return .run { send in
            await send(.internal(.viewerResponse(TaskResult {
                try await userClient.fetchUserProfile()
            })))
        }
        .cancellable(id: CancelID.viewer, cancelInFlight: true)
    }

    private func showToast(_ message: String, status: ToastState.Status) -> Effect<Action> {
        .send(.internal(.showToast(.init(message: message, status: status))))
    }

    /// 로그인이 만료됐으면 앱이 세션 만료 안내(로그인 버튼)를 띄우므로 실패 토스트를 겹치지 않는다.
    private func showMenuFailure(_ message: String, error: Error) -> Effect<Action> {
        if case let .apiError(code, _)? = error as? DomainError, code.endsSession {
            return .none
        }
        Log.trace("\(message): \(error)", category: .network, level: .error)
        analyticsClient.logErrorShown(error)
        return showToast(message, status: .error)
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
