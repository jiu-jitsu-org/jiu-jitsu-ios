//
//  AppFeature+UIClickAnalytics.swift
//  Presentation
//
//  이름 없는 누름 기록(#432). 이름 붙은 이벤트가 없는 앱 버튼만 남긴다 — 칩은 웹이 category_select로,
//  홈 · 대회 칸 전환은 screen_view로 남는다. 웹 버튼은 웹이 남긴다(FE #584).
//

import ComposableArchitecture

extension AppFeature.Analytics {
    /// 루트 Analytics는 자식 리듀서 뒤에 돈다. 탭 바 칸 · 맨 위로 누름은 상태를 바꾸지 않고 넘기기만 해서
    /// 여기서 보는 `selectedTab`은 누르기 전 탭이다.
    func reduceUIClickEvent(state: State, action: Action) {
        guard case let .destination(.presented(.appTab(appTab))) = action,
              case let .appTab(appTabState)? = state.destination else { return }
        let selectedTab = appTabState.selectedTab
        let element: AnalyticsEvent.UIElement?
        switch appTab {
        case .home(.view(.searchTapped)):
            element = .homeSearchButton
        case .home(.view(.notificationTapped)):
            element = .homeNotificationButton
        case .competition(.view(.notificationTapped)):
            element = .competitionNotificationButton
        case .home(.internal(.refreshStarted)):
            element = .homePullRefresh
        case .competition(.web(.internal(.refreshStarted))):
            element = .competitionPullRefresh
        case .view(.scrollToTopTapped):
            switch selectedTab {
            case .home: element = .homeScrollTop
            case .competition: element = .competitionScrollTop
            case .myPage: element = nil
            }
        case let .view(.tabBarItemTapped(tab)):
            switch tab {
            case .home: element = selectedTab == .home ? .homeTabReselect : nil
            case .competition: element = selectedTab == .competition ? .competitionTabReselect : nil
            case .myPage: element = .tabBarMy
            }
        default:
            element = nil
        }
        if let element {
            log(.uiClick(element))
        }
    }
}
