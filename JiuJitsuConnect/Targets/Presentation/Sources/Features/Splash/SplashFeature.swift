import ComposableArchitecture
import CoreKit
import Foundation
import Domain

@Reducer
public struct SplashFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        case onAppearLaunch
        case minimumDisplay
        case versionCheck
    }

    // 스플래시 최소 노출 시간
    private static let minimumDisplayDuration: Duration = .seconds(1.5)
    // 자동 로그인 확인을 기다리는 최대 시간(정책 2026-10-21, #75). 모바일 API 제한 시간으로 흔한 값 —
    // 5초는 느린 망에서 정상 사용자도 실패하고, 30초(공통 timeout)는 앱이 멈춘 것처럼 보인다.
    private static let maximumWaitDuration: Duration = .seconds(10)
    // 버전 확인 응답만 늦으면 이만큼에서 끊고 안내 없이 진행한다(#326). 자동 로그인보다 오래 붙잡지 않는다.
    private static let versionCheckWaitDuration: Duration = .seconds(3)

    private enum AutoLoginOutcome: Sendable {
        case completed(TaskResult<AuthInfo?>)
        case timedOut
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient
    @Dependency(\.homeFeedPreloadClient) var homeFeedPreload
    @Dependency(\.appVersionClient) var appVersionClient
    @Dependency(\.openURL) var openURL

    @ObservableState
    public struct State: Equatable {
        var isLaunching = false
        // 최소 노출 조건을 채움 — 시간이 지났거나, 공유 링크·푸시로 들어와 기다리지 않아도 됨(#300).
        var isMinimumDisplaySatisfied = false
        // 자동 로그인을 다 기다림. 결과가 비로그인(nil)인 것과 아직 기다리는 중을 가르려고 감싼다.
        var autoLoginResult: AutoLoginResult?
        // 버전 확인을 다 기다림(#326). 확인 실패 · 시간 초과는 `.upToDate`로 두어 안내 없이 진행한다.
        var updateRequirement: AppUpdateRequirement?
        // 공유 링크 · 푸시로 들어옴 — 권장 업데이트 안내를 건너뛰고 보려던 글로 간다(#326).
        var hasPendingDeepLink = false
        // 권장 업데이트 안내. 꼭 필요한 업데이트는 앱 전체를 막아야 해 AppFeature가 띄운다.
        var recommendedUpdateVersion: String?
        var hasFinished = false
        // 서버 연결 실패 안내 + [다시 시도](#367)
        var isConnectionFailurePresented = false

        public init() {}
    }
    
    struct AutoLoginResult: Equatable {
        let authInfo: AuthInfo?
        // 저장된 로그인이 만료로 끝남 — 로그인 화면에서 이유를 알린다(#373).
        var isSessionExpired = false
        // 저장된 로그인은 있는데 서버에 닿지 못함(망 없음 · 5xx · 시간 초과) — 로그인 화면 대신 다시 시도를 묻는다(#367).
        var isConnectionFailed = false
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        /// 스플래시 중에 공유 링크·푸시가 보관됐다. 그 글을 빨리 보여 주려고 최소 노출 시간을 기다리지 않는다(#300).
        case deepLinkPending

        public enum ViewAction: Sendable {
            case onAppear
            // 권장 업데이트 안내(#326)
            case recommendedUpdateTapped
            case recommendedUpdateLaterTapped
            case connectionRetryTapped
        }

        public enum InternalAction: Sendable {
            case minimumDisplayElapsed
            case autoLoginFinished(AuthInfo?, isSessionExpired: Bool = false)
            /// 저장된 로그인은 있는데 서버에 닿지 못함. 시간 초과인지는 분석(`session_restore`)이 가른다(#423).
            case autoLoginConnectionFailed(isTimedOut: Bool)
            case versionChecked(AppUpdateRequirement)
        }

        public enum DelegateAction: Sendable {
            case finishedLaunch(authInfo: AuthInfo?, isSessionExpired: Bool)
            // 꼭 필요한 업데이트 — 스플래시에서 넘어가지 않고, 부모가 닫을 수 없는 안내를 띄운다(#326).
            case updateRequired
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isLaunching else { return .none }
                state.isLaunching = true
                // 링크가 스플래시보다 먼저 와 있으면 최소 노출 시간을 재지 않는다.
                let minimumDisplay: Effect<Action> = state.isMinimumDisplaySatisfied
                    ? .none
                    : .run { send in
                        try await self.clock.sleep(for: Self.minimumDisplayDuration)
                        await send(.internal(.minimumDisplayElapsed))
                    }
                    .cancellable(id: CancelID.minimumDisplay, cancelInFlight: true)
                return .merge(minimumDisplay, autoLoginEffect(), checkVersion())

            case .deepLinkPending:
                state.isMinimumDisplaySatisfied = true
                state.hasPendingDeepLink = true
                return .merge(.cancel(id: CancelID.minimumDisplay), finishIfReady(&state))

            case .internal(.minimumDisplayElapsed):
                state.isMinimumDisplaySatisfied = true
                return finishIfReady(&state)

            case let .internal(.autoLoginFinished(authInfo, isSessionExpired)):
                state.autoLoginResult = AutoLoginResult(authInfo: authInfo, isSessionExpired: isSessionExpired)
                return finishIfReady(&state)

            case .internal(.autoLoginConnectionFailed):
                state.autoLoginResult = AutoLoginResult(authInfo: nil, isConnectionFailed: true)
                return finishIfReady(&state)

            case .view(.connectionRetryTapped):
                state.isConnectionFailurePresented = false
                state.autoLoginResult = nil
                // 같은 연결 실패로 버전 확인도 '최신'으로 넘겼을 수 있어 다시 확인한다 — 꼭 필요한 업데이트를 건너뛰지 않게.
                state.updateRequirement = nil
                return .merge(autoLoginEffect(), checkVersion())

            case let .internal(.versionChecked(requirement)):
                state.updateRequirement = requirement
                return finishIfReady(&state)

            case .view(.recommendedUpdateTapped):
                // 스토어에 다녀와도 쓰던 앱으로 돌아오게 홈으로 넘어간다. '나중에'가 아니라 다음 실행에 다시 안내한다.
                state.recommendedUpdateVersion = nil
                let storeURL = appVersionClient.storeURL()
                return .merge(
                    .run { _ in
                        guard let storeURL else { return }
                        await openURL(storeURL)
                    },
                    finish(&state)
                )

            case .view(.recommendedUpdateLaterTapped):
                guard let version = state.recommendedUpdateVersion else { return .none }
                state.recommendedUpdateVersion = nil
                appVersionClient.setDismissedRecommendedVersion(version)
                return finish(&state)

            case .delegate, .view:
                return .none
            }
        }
    }

    /// 서버의 최소 · 최신 버전을 자동 로그인과 함께 확인한다. 실패하거나 늦으면 안내 없이 진행한다(#326).
    private func checkVersion() -> Effect<Action> {
        .run { send in
            let policy = await withTaskGroup(of: AppVersionPolicy?.self) { group in
                group.addTask {
                    do {
                        return try await self.appVersionClient.fetchPolicy()
                    } catch {
                        Log.trace("⚠️ App version check failed: \(error)", category: .network, level: .error)
                        return nil
                    }
                }
                group.addTask {
                    try? await self.clock.sleep(for: Self.versionCheckWaitDuration)
                    return nil
                }
                // 먼저 끝난 쪽(응답 또는 시간 초과)을 쓴다. 시간 초과는 nil이다
                let first = await group.next().flatMap { $0 }
                group.cancelAll()
                return first
            }
            let requirement = policy?.requirement(for: appVersionClient.currentVersion()) ?? .upToDate
            Log.trace("App version check: \(requirement)", category: .debug, level: .info)
            await send(.internal(.versionChecked(requirement)))
        }
        .cancellable(id: CancelID.versionCheck, cancelInFlight: true)
    }

    /// 자동 로그인 · 버전 확인을 다 기다렸고 최소 노출 시간도 채웠으면(또는 링크로 들어와 건너뛰면) 한 번만 넘어간다.
    /// 꼭 필요한 업데이트면 넘어가지 않고, 권장 업데이트면 안내를 먼저 띄운다(#326).
    private func finishIfReady(_ state: inout State) -> Effect<Action> {
        guard
            !state.hasFinished,
            state.recommendedUpdateVersion == nil,
            state.isMinimumDisplaySatisfied,
            let result = state.autoLoginResult,
            let requirement = state.updateRequirement
        else { return .none }

        if case .required = requirement {
            state.hasFinished = true
            return .send(.delegate(.updateRequired))
        }
        // 꼭 필요한 업데이트 다음, 권장 업데이트 안내보다 먼저 묻는다 — 연결이 안 되면 업데이트 확인도 믿을 수 없다.
        if result.isConnectionFailed {
            state.isConnectionFailurePresented = true
            return .none
        }

        switch requirement {
        case .required:
            return .none
        case let .recommended(latestVersion)
            where !state.hasPendingDeepLink && appVersionClient.dismissedRecommendedVersion() != latestVersion:
            state.recommendedUpdateVersion = latestVersion
            return .none
        case .recommended, .upToDate:
            return finish(&state)
        }
    }

    /// 자동 로그인을 최대 10초 기다린다. 앱을 열 때와 연결 실패 뒤 [다시 시도](#367)가 같이 쓴다.
    private func autoLoginEffect() -> Effect<Action> {
        .run { send in
            // 자동 로그인은 비구조적 Task로 돌려, 10초에 기다림을 끊어도 요청은 취소되지 않게 한다.
            // refresh 토큰은 서버에서 1회용으로 회전되므로, 늦게 도착한 재발급 응답의 새 토큰도
            // autoLogin(AuthRepositoryImpl)이 저장해야 다음 실행의 자동 로그인이 깨지지 않는다.
            let autoLoginTask = Task { try await self.authClient.autoLogin() }

            // 저장된 access token이 아직 유효하면 자동 로그인을 기다리지 않고 홈 피드를 미리 불러 둔다(#270).
            // 서버는 토큰을 갱신해도 이전 access token을 막지 않아 그대로 써도 된다.
            // 미리 불러 둘 수 없으면(로그인 전·토큰 만료) 웹킷만 데워 둔다(#207).
            // 자동 로그인을 먼저 시작해, 웹뷰를 만드는 동안 밀리지 않게 한다.
            let homeURL = CommunityFeature.makeCommunityURL()
            var isPreloading = false
            if let homeURL, let token = self.authClient.storedAccessToken(), !JWTDecoder.isExpired(token) {
                await self.homeFeedPreload.preload(homeURL, token)
                isPreloading = true
            } else {
                await self.homeFeedPreload.prewarm()
            }

            let outcome = await Self.waitAtMost(Self.maximumWaitDuration, for: autoLoginTask, clock: self.clock)

            // 홈으로 가면, 미리 불러 두지 못했어도 새 토큰으로 지금 시작한다 — 스플래시 남은 시간만큼 겹친다.
            // 링크로 들어오면 남은 시간이 없어 이 대기만큼 늦게 넘어간다(순서 조정은 #301).
            // 로그인 화면으로 가면 미리 불러 둔 화면을 버린다.
            let authInfo: AuthInfo? = if case let .completed(.success(info)) = outcome { info } else { nil }
            if let accessToken = authInfo?.accessToken {
                if !isPreloading, let homeURL {
                    await self.homeFeedPreload.preload(homeURL, accessToken)
                }
            } else {
                await self.homeFeedPreload.discard()
            }

            switch outcome {
            case let .completed(.success(authInfo)):
                Log.trace("✅ Auto login check completed. AuthInfo: \(authInfo != nil)", category: .debug, level: .info)
                await send(.internal(.autoLoginFinished(authInfo)))
            case let .completed(.failure(error)):
                Log.trace("⚠️ Auto login failed: \(error)", category: .debug, level: .error)
                // autoLogin은 저장된 로그인이 없으면 nil을 돌려주므로, 실패는 저장된 로그인이 있다는 뜻이다.
                // 서버가 세션 종료를 알렸을 때만 로그인 화면으로 가고, 그 밖엔 토큰을 지키고 다시 시도를 묻는다(#367).
                if case let .apiError(code, _)? = error as? DomainError, code.endsSession {
                    // 미리 불러오기가 심은 세션 쿠키를 지운다. 남으면 둘러보기 · 링크로 연 게스트 홈이 이전 계정으로 잠깐 그려진다.
                    await WebSessionCookie.clear()
                    await send(.internal(.autoLoginFinished(nil, isSessionExpired: true)))
                } else {
                    await send(.internal(.autoLoginConnectionFailed(isTimedOut: false)))
                }
            case .timedOut:
                // 저장된 토큰은 지우지 않는다. 요청은 계속 돌고, [다시 시도]가 그 결과에 합류한다.
                Log.trace("⚠️ Auto login timed out after \(Self.maximumWaitDuration)", category: .debug, level: .error)
                await send(.internal(.autoLoginConnectionFailed(isTimedOut: true)))
            }
        }
        .cancellable(id: CancelID.onAppearLaunch, cancelInFlight: true)
    }

    /// 자동 로그인을 `duration`까지만 기다린다. 먼저 끝난 쪽 하나만 결과로 쓴다.
    /// TaskGroup으로 두 자식을 경쟁시키면 그룹이 남은 자식까지 기다리고, `Task.value`는 기다리는 쪽이
    /// 취소돼도 돌아오지 않아 시간 초과가 걸리지 않는다(#367). 그래서 두 비구조적 Task가 한 번만 넘긴다.
    private static func waitAtMost(
        _ duration: Duration,
        for task: Task<AuthInfo?, Error>,
        clock: any Clock<Duration>
    ) async -> AutoLoginOutcome {
        await withCheckedContinuation { continuation in
            let isResumed = LockIsolated(false)
            let resumeOnce: @Sendable (AutoLoginOutcome) -> Void = { outcome in
                let shouldResume = isResumed.withValue { resumed in
                    defer { resumed = true }
                    return !resumed
                }
                if shouldResume { continuation.resume(returning: outcome) }
            }
            Task { resumeOnce(.completed(await TaskResult { try await task.value })) }
            Task {
                try? await clock.sleep(for: duration)
                resumeOnce(.timedOut)
            }
        }
    }

    private func finish(_ state: inout State) -> Effect<Action> {
        guard !state.hasFinished, let result = state.autoLoginResult else { return .none }
        state.hasFinished = true
        return .send(.delegate(.finishedLaunch(authInfo: result.authInfo, isSessionExpired: result.isSessionExpired)))
    }
}
