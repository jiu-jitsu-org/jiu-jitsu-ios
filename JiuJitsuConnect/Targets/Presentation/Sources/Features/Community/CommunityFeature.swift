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

    @ObservableState
    public struct State: Equatable {
        var url: URL?
        // 같은 URL로 재시도 시 View가 reload를 인지하도록 토큰을 갱신한다.
        var loadToken: UUID = UUID()
        var isLoading: Bool = true
        var hasError: Bool = false

        public init() {
            self.url = CommunityFeature.makeCommunityURL()
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)

        public enum ViewAction: Sendable {
            case onAppear
            case retryTapped
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

            case .view(.retryTapped):
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
