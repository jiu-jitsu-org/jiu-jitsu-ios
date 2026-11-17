//
//  AppTabFeature+Session.swift
//  Presentation
//
//  게스트 전환(로그아웃 · 탈퇴 · 세션 만료)과 웹 세션 알림 도우미, 세션 만료 안내(#373).
//

import ComposableArchitecture

/// 세션 만료 안내 문구(#373). 앱 사용 중 알럿과 앱을 열 때 로그인 화면 토스트가 같은 말을 쓴다.
enum SessionExpiryNotice {
    static let title = "로그인이 만료됐어요"
    static let body = "다시 로그인해 주세요."
    static let message = "\(title). \(body)"
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
