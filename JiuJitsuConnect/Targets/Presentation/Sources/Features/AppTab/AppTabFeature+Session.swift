//
//  AppTabFeature+Session.swift
//  Presentation
//
//  게스트 전환(로그아웃 · 탈퇴 · 세션 만료)과 웹 세션 알림 도우미, 세션 만료 안내(#373).
//

import ComposableArchitecture
import DesignSystem
import Domain

/// 세션 만료 안내 문구(#373). 앱 사용 중 알럿과 앱을 열 때 로그인 화면 토스트가 같은 말을 쓴다.
enum SessionExpiryNotice {
    static let title = "로그인이 만료됐어요"
    static let body = "다시 로그인해 주세요."
    static let message = "\(title). \(body)"
}

/// 탈퇴 · 로그아웃 · 계정 복구가 끝났다는 안내(#385). 설정의 탈퇴 확인 알럿과 같은 사실(30일 · 다시 로그인하면 취소)을 말한다.
enum AccountNotice {
    static let withdrawalTitle = "탈퇴 신청이 끝났어요"
    static let withdrawalBody = "30일 뒤 계정이 삭제돼요. 그 전에 같은 계정으로 로그인하면 탈퇴가 취소돼요."
    // 토스트마다 새 id가 필요해 매번 만든다.
    static var loggedOutToast: ToastState { ToastState(message: "로그아웃했어요", status: .success) }
    static var restoredToast: ToastState { ToastState(message: "탈퇴를 취소하고 계정을 되살렸어요", status: .success) }
}

extension AppTabFeature {
    public enum SessionExpiredAlertAction: Sendable {
        case loginTapped
        case closeTapped
        case dismissed
    }

    /// 어떤 소셜로 가입했는지 떠올리다 다른 버튼으로 새 계정을 만들지 않게, 만료됐다고 알리고 바로 로그인 창을 연다.
    static func reduceSessionExpiredAlert(_ action: SessionExpiredAlertAction, into state: inout State) -> Effect<Action> {
        state.isSessionExpiredAlertPresented = false
        switch action {
        case .loginTapped:
            return .send(.internal(.showLoginModal))
        case .closeTapped, .dismissed:
            // 그사이 웹이 로그인을 요청했으면(만료 직후 관심 등록 등) 그 행위를 버리게 한다.
            return cancelPendingWebLogin(&state)
        }
    }

    /// 탈퇴 성공 — 게스트로 바꾸고 로컬 세션을 정리한 뒤 탈퇴 안내를 띄운다(#385).
    func finishWithdrawal(_ state: inout State) -> Effect<Action> {
        Self.resetToGuest(&state)
        return .merge(
            Self.broadcastLoggedOut(),
            .cancel(id: CancelID.notificationPermission),
            .cancel(id: CancelID.deviceTokenSync),
            .cancel(id: CancelID.webTokenRefresh),
            // 로컬 세션 정리를 끝낸 뒤 안내한다. 먼저 안내하면 [확인] 뒤 바로 로그인한 토큰을
            // 뒤늦은 signOut이 지우거나, 새 로그인이 폐기 직전의 FCM 토큰을 등록할 수 있다.
            // 로그인 창은 띄우지 않는다 — 유예 중 같은 계정으로 로그인하면 탈퇴가 취소되기 때문이다.
            .run { send in
                await authClient.signOut()
                await WebSessionCookie.clear()
                await Self.discardDeviceFCMToken(firebaseClient, context: "withdrawal")
                await send(.internal(.withdrawalCleanupFinished))
            }
        )
    }

    /// 탭 안 로그인 창으로 들어온 계정이 탈퇴 유예 중이었으면 서버가 되살렸다고 알린다(#385).
    /// 모르는 사이 탈퇴가 취소되지 않게 한다.
    static func noticeIfRestored(_ authInfo: AuthInfo) -> Effect<Action> {
        guard authInfo.userInfo?.deactivatedWithinGrace == true else { return .none }
        return .send(.internal(.showToast(AccountNotice.restoredToast)))
    }

    /// 탈퇴 안내 알럿과 탭 화면 토스트(로그아웃 · 계정 복구, #385).
    func reduceAccountNotice(_ action: Action, into state: inout State) -> Effect<Action> {
        switch action {
        case .internal(.withdrawalCleanupFinished):
            // 정리하는 사이 다시 로그인했으면(같은 계정이면 탈퇴 취소) '탈퇴 신청이 끝났어요'는 틀린 안내라 띄우지 않는다.
            guard state.authInfo.isGuest else { return .none }
            state.isWithdrawalNoticePresented = true
            return .none
        case .view(.withdrawalNoticeDismissed):
            state.isWithdrawalNoticePresented = false
            return .none
        case .accountRestored:
            return .send(.internal(.showToast(AccountNotice.restoredToast)))
        case let .internal(.showToast(toast)):
            state.toast = toast
            return .run { [clock] send in
                try await clock.sleep(for: toast.duration)
                await send(.internal(.toastDismissed))
            }
            .cancellable(id: CancelID.toast, cancelInFlight: true)
        case .internal(.toastDismissed), .view(.toastSwiped):
            state.toast = nil
            return .cancel(id: CancelID.toast)
        default:
            return .none
        }
    }

    /// 로그아웃·탈퇴·세션 만료 — 게스트로 바꾸고 이전 계정의 화면을 정리한 뒤 홈으로 보낸다.
    static func resetToGuest(_ state: inout State) {
        state.authInfo = .guest
        state.isDeviceNotificationAlertPresented = false
        state.isNotificationPromptPresented = false
        state.pendingWebLoginTab = nil
        state.pendingCompetitionRecord = nil
        // 이전 계정으로 대회 탭에 쌓아 둔 상세·프로필도 닫는다.
        state.competition.path.removeAll()
        // MY 스택에 열어 둔 설정·웹 화면도 함께 닫힌다.
        state.myPage = MyProfileFeature.State(authInfo: .guest)
        // 이전 계정으로 커뮤니티에 쌓아 둔 MY 화면(#197)·대회 기록 추가(#304)도 닫는다.
        CommunityFeature.closeAccountScreens(into: &state.home)
        state.selectedTab = .home
    }

    /// 네이티브 로그아웃을 홈·대회 웹 세션에도 알린다.
    static func broadcastLoggedOut() -> Effect<Action> {
        .merge(
            .send(.home(.session(.loggedOut))),
            .send(.competition(.session(.loggedOut)))
        )
    }

    /// 웹발 로그인을 취소 — 그 웹이 보관한 행위(글쓰기·관심 등록 등)를 버리게 한다.
    static func cancelPendingWebLogin(_ state: inout State) -> Effect<Action> {
        let tab = state.pendingWebLoginTab
        state.pendingWebLoginTab = nil
        state.pendingCompetitionRecord = nil
        switch tab {
        case .home:
            return .send(.home(.session(.loginCancelled)))
        case .competition:
            return .send(.competition(.session(.loginCancelled)))
        case .myPage, nil:
            return .none
        }
    }
}
