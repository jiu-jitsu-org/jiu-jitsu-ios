//
//  AppTabFeature+HomeFeed.swift
//  Presentation
//
//  웹이 '피드로 가기'(OPEN_HOME_FEED)를 보냈을 때 어느 탭에서 왔든 홈 피드 맨 위로 보낸다(#250 · #304 · #386).
//  대회 상세의 '커뮤니티에서 더 보기', 커뮤니티 활동 빈 밸런스 게임 탭의 '오늘의 게임 하러 가기'(jiu-jitsu-frontend#532).
//

import ComposableArchitecture
import Foundation

extension AppTabFeature {
    /// 홈에 쌓인 화면을 닫고 피드를 맨 위로 올린 뒤(closeToFeed) 홈 탭을 보인다. 연 탭에 따라 더 닫는 것이 다르다.
    /// - 대회(#250): 대회 스택도 닫고 홈 탭으로
    /// - 홈(#304): 이미 홈 탭이다. 대회 탭 스택은 그 탭에서 보던 화면이라 건드리지 않는다.
    ///   알림함을 거쳐 왔으면 뒤로가기(popFrom)를 거치지 않고 닫히므로 새 알림 점을 여기서 다시 조회한다.
    /// - MY(#386): MY에 열어 둔 화면(커뮤니티 활동)을 닫고 홈 탭으로
    /// 탭을 바꾸면 홈 진입 처리(새 알림 점 갱신)는 탭 선택이 함께 한다.
    static func showHomeFeed(from tab: Tab, into state: inout State) -> Effect<Action> {
        CommunityFeature.closeToFeed(into: &state.home)
        switch tab {
        case .home:
            return .send(.home(.unreadNotificationRefreshRequested))
        case .competition:
            state.competition.path.removeAll()
        case .myPage:
            state.myPage.path.removeAll()
        }
        return .send(.view(.tabSelected(.home)))
    }

    /// MY 탭 스택에 쌓는 '커뮤니티 활동' 웹뷰. 빈 밸런스 게임 탭의 '오늘의 게임 하러 가기'가 홈 피드로 보내 달라고 하므로
    /// 홈 스택에서 연 활동(CommunityFeature.subview)처럼 OPEN_HOME_FEED를 받는다고 알린다(#386).
    static func myTabActivity(url: URL, accessToken: String?) -> CommunityDetailFeature.State {
        CommunityDetailFeature.State(
            url: url,
            accessToken: accessToken,
            isTabRoot: false,
            capabilities: [.pickPhotos, .openHomeFeed]
        )
    }
}
