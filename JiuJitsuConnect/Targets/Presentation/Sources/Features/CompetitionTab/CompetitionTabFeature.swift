//
//  CompetitionTabFeature.swift
//  Presentation
//
//  하단 탭 '대회'(#240). 웹 대회 목록(`/competition`)을 탭 첫 화면으로 띄운다.
//  웹뷰와 브릿지 처리는 커뮤니티 상세 웹(CommunityDetailFeature)을 그대로 쓰고, 탭 첫 화면이라 스스로 닫지 않게 한다.
//  웹이 여는 대회 상세 등은 이 탭 스택에 쌓고, 로그인·토큰처럼 앱 전체에 걸친 일은 부모(AppTab)에 맡긴다.
//

import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct CompetitionTabFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        // 대회 목록 웹. 웹 주소를 만들 수 없으면(WEB_URL 없음) nil — 화면은 오류 안내를 보인다.
        var web: CommunityDetailFeature.State?
        // 웹이 OPEN_SUBVIEW로 여는 화면(대회 상세 등)과 회원 프로필
        var path = StackState<Path.State>()
        // 값이 바뀌면 목록을 맨 위로 올린다(탭 아이콘 다시 누름, 홈 #229와 같은 동작).
        var scrollToTopToken: UUID?

        /// - Parameter base: 커뮤니티 웹과 같은 origin(테스트용 도메인 오버라이드 포함). 세션 쿠키를 가진 웹뷰에 다른 origin이 실리지 않게 한다.
        public init(base: URL?, accessToken: String?) {
            self.web = base.flatMap(Self.competitionURL(base:)).map {
                CommunityDetailFeature.State(
                    url: $0,
                    accessToken: accessToken,
                    isTabRoot: true,
                    // 사진 고르기는 쌓인 상세 화면만 띄울 수 있어 목록에서는 알리지 않는다.
                    capabilities: [.requestNotificationPermission]
                )
            }
        }

        /// 대회 탭에 쌓인 웹이 알리는 기능. 관심 첫 등록 때 알림 권한을 물을 수 있다(#243).
        static let subviewCapabilities: [WebBridgeCapability] = [.pickPhotos, .requestNotificationPermission]

        static func competitionURL(base: URL) -> URL? {
            URL(string: "/competition", relativeTo: base)?.absoluteURL
        }
    }

    @Reducer
    public enum Path {
        case communityDetail(CommunityDetailFeature)
        case userProfile(UserProfileFeature)
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case web(CommunityDetailFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
        case delegate(DelegateAction)
        // 부모(AppTab)가 세션 변화(로그인·토큰 갱신·로그아웃)를 이 탭의 웹뷰 전부에 전파한다.
        case session(CommunityDetailFeature.SessionUpdate)
        // 부모가 알림 권한을 묻고 난 결과 → 요청한 웹뷰에 회신한다(#243).
        case notificationPermissionResolved(requestId: String?, status: NotificationPermissionStatus)

        public enum ViewAction: Sendable {
            case tabReselected
        }

        public enum DelegateAction: Sendable {
            // 웹의 인증류·알림 권한 위임 → 부모가 커뮤니티와 같은 흐름으로 처리한다.
            case webSubview(CommunityDetailFeature.Action.DelegateAction)
            case myTabRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.tabReselected):
                // 대회 상세 등이 위에 쌓여 있으면 목록이 보이지 않으니 움직이지 않는다(홈과 같은 기준).
                guard state.path.isEmpty else { return .none }
                state.scrollToTopToken = UUID()
                return .none

            // MARK: - 목록 웹

            case let .web(.delegate(.openSubviewRequested(payload))):
                // 동일 origin 검증은 상세가 위임 전에 끝냈다. 탭 안이라 modal 요청도 push로 쌓는다.
                guard let url = URL(string: payload.url) else { return .none }
                state.path.append(.communityDetail(Self.subview(url: url, title: payload.title, accessToken: state.web?.accessToken)))
                return .none

            case let .web(.delegate(.userProfileRequested(userId))):
                return Self.openUserProfile(userId: userId, into: &state)

            case .web(.delegate(.myTabRequested)):
                return .send(.delegate(.myTabRequested))

            case let .web(.delegate(delegate)):
                return .send(.delegate(.webSubview(delegate)))

            case .web:
                return .none

            // MARK: - 쌓인 웹

            case let .path(.element(id: id, action: .communityDetail(.delegate(.openSubviewRequested(payload))))):
                guard
                    case let .communityDetail(source)? = state.path[id: id],
                    let url = URL(string: payload.url)
                else { return .none }
                state.path.append(.communityDetail(Self.subview(url: url, title: payload.title, accessToken: source.accessToken)))
                return .none

            case let .path(.element(id: _, action: .communityDetail(.delegate(.userProfileRequested(userId))))):
                return Self.openUserProfile(userId: userId, into: &state)

            case .path(.element(id: _, action: .communityDetail(.delegate(.myTabRequested)))):
                return .send(.delegate(.myTabRequested))

            case let .path(.element(id: _, action: .communityDetail(.delegate(delegate)))):
                return .send(.delegate(.webSubview(delegate)))

            case .path:
                return .none

            // MARK: - 부모가 내려 주는 것

            case let .session(update):
                if var web = state.web {
                    CommunityDetailFeature.apply(update, into: &web)
                    state.web = web
                }
                for id in state.path.ids {
                    if case var .communityDetail(detail)? = state.path[id: id] {
                        CommunityDetailFeature.apply(update, into: &detail)
                        state.path[id: id] = .communityDetail(detail)
                    }
                }
                return .none

            case let .notificationPermissionResolved(requestId, status):
                // 어느 웹뷰가 물었는지는 모르므로 이 탭에 열린 웹 전부에 회신한다. requestId가 다르거나
                // 기다리는 요청이 없는 웹은 회신을 무시한다.
                if var web = state.web {
                    CommunityDetailFeature.deliverNotificationPermission(requestId: requestId, status: status, into: &web)
                    state.web = web
                }
                for id in state.path.ids {
                    if case var .communityDetail(detail)? = state.path[id: id] {
                        CommunityDetailFeature.deliverNotificationPermission(requestId: requestId, status: status, into: &detail)
                        state.path[id: id] = .communityDetail(detail)
                    }
                }
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.web, action: \.web) {
            CommunityDetailFeature()
        }
        .forEach(\.path, action: \.path)
    }

    private static func subview(url: URL, title: String?, accessToken: String?) -> CommunityDetailFeature.State {
        CommunityDetailFeature.State(
            url: url,
            title: title,
            accessToken: accessToken,
            isTabRoot: false,
            capabilities: State.subviewCapabilities
        )
    }

    private static func openUserProfile(userId: Int, into state: inout State) -> Effect<Action> {
        // 연타·중복 전달로 같은 프로필이 겹쳐 쌓이지 않게 한다
        if case let .userProfile(current)? = state.path.last, current.userId == userId { return .none }
        state.path.append(.userProfile(.init(userId: userId)))
        return .none
    }
}

extension CompetitionTabFeature.Path.State: Equatable, Sendable {}
extension CompetitionTabFeature.Path.Action: Sendable {}
