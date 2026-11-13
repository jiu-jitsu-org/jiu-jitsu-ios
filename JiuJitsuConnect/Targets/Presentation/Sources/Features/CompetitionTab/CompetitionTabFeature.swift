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
        // 웹이 알린 목록 맨 위 색(`#RRGGBB`). 머리줄·상태바를 이 색으로 칠해 웹 그라데이션과 이음새가 없게 한다. nil이면 기본색.
        var headerTint: String?

        /// - Parameter base: 커뮤니티 웹과 같은 origin(테스트용 도메인 오버라이드 포함). 세션 쿠키를 가진 웹뷰에 다른 origin이 실리지 않게 한다.
        public init(base: URL?, accessToken: String?) {
            self.web = base.flatMap(Self.competitionURL(base:)).map {
                CommunityDetailFeature.State(
                    url: $0,
                    accessToken: accessToken,
                    isTabRoot: true,
                    // 사진 고르기는 쌓인 상세 화면만 띄울 수 있어 목록에서는 알리지 않는다.
                    // 머리줄 색은 이 탭 머리줄 아래 붙은 목록만 알린다.
                    capabilities: [.competitionHeaderTint]
                )
            }
        }

        /// 대회 탭에 쌓인 웹이 알리는 기능. 대회 상세의 '커뮤니티에서 더 보기'·'내 기록에 남기기'를 네이티브가 받는다(#250).
        static let subviewCapabilities: [WebBridgeCapability] = [
            .pickPhotos,
            .openHomeFeed,
            .openCompetitionRecord
        ]

        // 머리줄의 알림함 종은 로그인한 사람만 본다(홈과 같은 알림함 정책, #258). 점 값은 홈이 가진 것을 받아 그린다.
        var isNotificationButtonVisible: Bool { web?.accessToken != nil }

        static func competitionURL(base: URL) -> URL? {
            URL(string: "/competition", relativeTo: base)?.absoluteURL
        }
    }

    @Reducer
    public enum Path {
        case communityDetail(CommunityDetailFeature)
        case userProfile(UserProfileFeature)
        // 대회 상세의 '내 기록에 남기기'로 여는 대회 기록 추가(#250). 저장은 프로필을 아는 부모(AppTab)가 한다.
        case competitionInfo(CompetitionInfoFeature)
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case web(CommunityDetailFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
        case delegate(DelegateAction)
        // 부모(AppTab)가 세션 변화(로그인·토큰 갱신·로그아웃)를 이 탭의 웹뷰 전부에 전파한다.
        case session(CommunityDetailFeature.SessionUpdate)
        // 부모가 유니버설 링크(`/competition/{id}`)로 들어온 대회 상세를 이 탭 스택에 연다(#250).
        case openDetail(url: URL, accessToken: String?)

        public enum ViewAction: Sendable {
            case tabReselected
            // 머리줄의 알림함 종(#258) → 홈과 같은 알림함 웹을 이 탭 스택에 쌓는다.
            case notificationTapped
        }

        public enum DelegateAction: Sendable {
            // 웹의 인증류 위임 → 부모가 커뮤니티와 같은 흐름으로 처리한다.
            case webSubview(CommunityDetailFeature.Action.DelegateAction)
            case myTabRequested
            // 관심 대회 첫 등록 시트의 '알림 받기'(#257) → 부모가 알림 설정을 켜고 기기 알림 상태를 본다.
            case competitionAlertsEnabled(competitionId: Int?)
            // 이 탭에서 연 알림함을 닫음(#258) → 부모가 홈의 새 알림 점을 다시 조회시킨다(이 탭의 종도 같은 값을 그린다).
            case unreadNotificationRefreshRequested
            // 대회 상세의 '커뮤니티에서 더 보기'(#250) → 부모가 이 스택을 닫고 홈 탭으로 바꾼다.
            case homeFeedRequested
            // 끝난 대회의 '내 기록에 남기기'(#250) → 부모가 로그인 여부를 보고 기록 추가를 이 스택에 쌓는다.
            case competitionRecordRequested(OpenCompetitionRecordPayload)
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

            case .view(.notificationTapped):
                guard
                    state.isNotificationButtonVisible,
                    let web = state.web,
                    let url = NotificationInbox.url(base: web.url)
                else { return .none }
                // 연타로 알림함이 겹쳐 쌓이지 않게 한다.
                guard !Self.isNotificationsDetail(state.path.last) else { return .none }
                state.path.append(.communityDetail(.init(url: url, accessToken: web.accessToken)))
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

            case let .web(.delegate(.competitionAlertsEnabled(competitionId))):
                return .send(.delegate(.competitionAlertsEnabled(competitionId: competitionId)))

            case let .web(.delegate(.competitionHeaderTintChanged(hex))):
                state.headerTint = hex
                return .none

            case let .web(.delegate(delegate)):
                return .send(.delegate(.webSubview(delegate)))

            case .web(.internal(.loadingFailed)):
                // 불러오기에 실패하면 오류 화면 위에 지난 색이 남지 않게 기본색으로 돌린다.
                // 시작할 때 지우지 않는 건 당겨서 새로고침 동안 머리·밴드가 흰색으로 깜빡이지 않게 하려는 것 —
                // 다시 그려진 웹은 붙자마자 색(또는 null)을 다시 보낸다.
                state.headerTint = nil
                return .none

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

            case let .path(.element(id: _, action: .communityDetail(.delegate(.competitionAlertsEnabled(competitionId))))):
                return .send(.delegate(.competitionAlertsEnabled(competitionId: competitionId)))

            case .path(.element(id: _, action: .communityDetail(.delegate(.homeFeedRequested)))):
                return .send(.delegate(.homeFeedRequested))

            case let .path(.element(id: _, action: .communityDetail(.delegate(.competitionRecordRequested(payload))))):
                return .send(.delegate(.competitionRecordRequested(payload)))

            case let .path(.element(id: _, action: .communityDetail(.delegate(delegate)))):
                return .send(.delegate(.webSubview(delegate)))

            // 알림함에서 읽은 알림을 점에 반영한다(홈과 같은 처리). forEach보다 먼저 실행돼 pop 대상이 아직 스택에 남아 있고,
            // 알림함 위에 쌓인 상세까지 한 번에 닫히는 경우도 있어 pop 범위 전체를 본다.
            case let .path(.popFrom(id)):
                guard
                    let index = state.path.ids.firstIndex(of: id),
                    state.path.ids[index...].contains(where: { Self.isNotificationsDetail(state.path[id: $0]) })
                else { return .none }
                return .send(.delegate(.unreadNotificationRefreshRequested))

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

            case let .openDetail(url, accessToken):
                // 같은 대회가 이미 맨 위면 다시 쌓지 않는다(링크 재탭·중복 전달, 홈 딥링크의 isTopDetail과 같은 이유).
                // 공유 링크엔 꼬리(?utm=…, 끝 '/')가 붙을 수 있어 주소 전체가 아니라 호스트·경로로 같은 대회인지 본다.
                if case let .communityDetail(top)? = state.path.last, Self.isSameDetail(top.url, url) {
                    Log.trace("대회 딥링크 무시(이미 최상단): \(url.absoluteString)", category: .view, level: .info)
                    return .none
                }
                var detail = Self.subview(url: url, title: nil, accessToken: accessToken)
                detail.entryOrigin?.via = .deeplink
                state.path.append(.communityDetail(detail))
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

    /// 두 상세 주소가 같은 화면인지 — 호스트와 끝 '/'를 뗀 경로만 비교한다(쿼리·조각은 무시).
    private static func isSameDetail(_ lhs: URL, _ rhs: URL) -> Bool {
        func key(_ url: URL) -> String {
            var path = url.path
            while path.count > 1, path.hasSuffix("/") { path.removeLast() }
            return "\(url.host?.lowercased() ?? "")\(path)"
        }
        return key(lhs) == key(rhs)
    }

    private static func isNotificationsDetail(_ element: Path.State?) -> Bool {
        guard case let .communityDetail(detail)? = element else { return false }
        return NotificationInbox.isInbox(detail.url)
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
