//
//  CommunityFeature.swift
//  Presentation
//
//  커뮤니티 탭 컨테이너 — 외부 웹 페이지를 WKWebView로 렌더링한다.
//  실제 커뮤니티 기능(피드/글쓰기 등)은 웹쪽에서 구현되며,
//  여기서는 URL 로딩 상태(로딩/에러/재시도)만 TCA로 관리한다.
//

import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct CommunityFeature: Sendable {
    public init() {}

    public enum Tab: String, CaseIterable, Sendable, Equatable {
        case feed
        case category

        var title: String {
            switch self {
            case .feed: return "피드"
            case .category: return "카테고리"
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .feed
        var url: URL?
        // 같은 URL로 재시도 시 View가 reload를 인지하도록 토큰을 갱신한다.
        var loadToken: UUID = UUID()
        var isLoading: Bool = true
        var hasError: Bool = false

        public init() {
            let url = CommunityFeature.makeCommunityURL()
            self.url = url
            // URL 자체를 만들 수 없으면 WKWebView가 생성되지 않아 로딩 콜백이 영영 오지 않는다.
            // 사용자에게 무한 로딩 대신 재시도 오버레이를 보여주기 위해 에러 상태로 초기화한다.
            if url == nil {
                self.isLoading = false
                self.hasError = true
            }
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
            case tabSelected(Tab)
            case notificationTapped
            case searchTapped
        }

        public enum InternalAction: Sendable {
            case loadingStarted
            case loadingFinished
            case loadingFailed
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                if state.url == nil {
                    state.url = Self.makeCommunityURL()
                }
                return .none

            case let .view(.tabSelected(tab)):
                state.selectedTab = tab
                return .none

            // FIXME: 알림 화면 진입 (네이티브 알림 센터 도입 시 구현)
            case .view(.notificationTapped):
                return .none

            // FIXME: 검색 화면 진입 (커뮤니티 검색 기능 도입 시 구현)
            case .view(.searchTapped):
                return .none

            case .view(.retryTapped):
                // URL이 아직도 nil이면 WKWebView가 생성되지 않으므로 재시도해도 콜백이 오지 않는다.
                // 다시 만들어보고, 그래도 실패하면 에러 상태를 유지한다.
                if state.url == nil {
                    state.url = Self.makeCommunityURL()
                }
                guard state.url != nil else {
                    state.hasError = true
                    state.isLoading = false
                    return .none
                }
                state.hasError = false
                state.isLoading = true
                state.loadToken = UUID()
                return .none

            case .internal(.loadingStarted):
                state.isLoading = true
                state.hasError = false
                return .none

            case .internal(.loadingFinished):
                state.isLoading = false
                state.hasError = false
                return .none

            case .internal(.loadingFailed):
                state.isLoading = false
                state.hasError = true
                return .none
            }
        }
    }

    private static func makeCommunityURL() -> URL? {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "COMMUNITY_WEB_URL") as? String,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            Log.trace("COMMUNITY_WEB_URL is not set in Info.plist", category: .system, level: .error)
            return nil
        }
        return url
    }
}
