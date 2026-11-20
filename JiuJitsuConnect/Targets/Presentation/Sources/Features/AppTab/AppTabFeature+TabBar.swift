//
//  AppTabFeature+TabBar.swift
//  Presentation
//
//  탭 바의 칸 선택 · 맨 위로(#432에서 AppTabFeature 본문에서 옮김). 칸 선택은 사람이 누를 때(tabBarItemTapped)와
//  코드가 탭을 바꿀 때 같이 쓴다.
//

import ComposableArchitecture

extension AppTabFeature {
    static func selectTab(_ tab: Tab, into state: inout State) -> Effect<Action> {
        // MY를 떠나면 띠 링 대기를 푼다 — 안 보이는 MY에서 돌지 않고, 다음 MY 진입 때 돈다(#320).
        if tab != .myPage {
            state.myPage.isWaitingBeltEntrance = false
        }
        // 이미 홈인데 홈 아이콘을 다시 누르면 피드를 맨 위로 올린다(#229).
        if tab == .home, state.selectedTab == .home {
            return .send(.home(.view(.tabReselected)))
        }
        // 다른 탭에서 커뮤니티로 돌아오면 새 알림 점을 갱신한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음).
        if tab == .home, state.selectedTab != .home {
            state.selectedTab = tab
            return .send(.home(.view(.tabEntered)))
        }
        // 이미 대회인데 대회 아이콘을 다시 누르면 목록을 맨 위로 올린다(#240, 홈과 같은 동작).
        if tab == .competition, state.selectedTab == .competition {
            return .send(.competition(.view(.tabReselected)))
        }
        // 대회 탭 머리줄의 종도 홈의 새 알림 점을 그리므로, 들어올 때 홈에 다시 조회시킨다(#258).
        let refreshUnread: Effect<Action> = tab == .competition && state.selectedTab != .competition
            ? .send(.home(.unreadNotificationRefreshRequested))
            : .none
        // 처음 만들 때 웹 주소가 없었으면(커뮤니티 주소 미정) 들어올 때 다시 만든다 — 홈이 다시 시도해 주소를 얻었을 수 있다.
        if tab == .competition, state.competition.web == nil {
            // 토큰은 갱신이 반영된 커뮤니티 쪽 값을 쓴다(authInfo는 갱신 때 바뀌지 않는다).
            state.competition = CompetitionTabFeature.State(
                base: state.home.url,
                accessToken: state.home.accessToken ?? state.authInfo.accessToken
            )
        }
        // 비로그인도 MY를 연다 — 로그인 안내와 설정 입구가 있다(#242).
        // 다른 탭에서 MY로 돌아오면 프로필을 재조회한다(탭 뷰가 유지돼 onAppear가 다시 오지 않음, #69).
        let isEnteringMyPage = tab == .myPage && state.selectedTab != .myPage
        state.selectedTab = tab
        if isEnteringMyPage, !state.authInfo.isGuest {
            return .send(.myPage(.view(.tabEntered)))
        }
        return refreshUnread
    }

    /// 맨 위로 칸 · 동그라미. MY에서는 뜨지 않는다.
    static func scrollToTop(_ state: State) -> Effect<Action> {
        switch state.selectedTab {
        case .home: return .send(.home(.view(.tabReselected)))
        case .competition: return .send(.competition(.view(.tabReselected)))
        case .myPage: return .none
        }
    }
}
