import ComposableArchitecture
import CoreKit
import Foundation
import Domain

@Reducer
public struct SplashFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        case onAppearLaunch
    }

    // 스플래시 최소 노출 시간
    private static let minimumDisplayDuration: Duration = .seconds(1.5)
    // 자동 로그인 확인을 기다리는 최대 시간(정책 2026-10-21, #75). 모바일 API 제한 시간으로 흔한 값 —
    // 5초는 느린 망에서 정상 사용자도 실패하고, 30초(공통 timeout)는 앱이 멈춘 것처럼 보인다.
    private static let maximumWaitDuration: Duration = .seconds(10)

    private enum AutoLoginOutcome: Sendable {
        case completed(TaskResult<AuthInfo?>)
        case timedOut
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient

    @ObservableState
    public struct State: Equatable {
        var isLaunching = false
        @Presents public var alert: AlertState<Alert>?

        public init() {}
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        
        public enum ViewAction: Sendable {
            case onAppear
        }
        
        public enum DelegateAction: Sendable {
            case finishedLaunch(authInfo: AuthInfo?)
        }
    }
    
    public enum Alert: Sendable {
        case goToUpdateTapped
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isLaunching else { return .none }
                state.isLaunching = true
                return .run { send in
                    async let splashDelay: Void = self.clock.sleep(for: Self.minimumDisplayDuration)

                    // 자동 로그인은 비구조적 Task로 돌려, 10초에 기다림을 끊어도 요청은 취소되지 않게 한다.
                    // refresh 토큰은 서버에서 1회용으로 회전되므로, 늦게 도착한 재발급 응답의 새 토큰도
                    // autoLogin(AuthRepositoryImpl)이 저장해야 다음 실행의 자동 로그인이 깨지지 않는다.
                    let autoLoginTask = Task { try await self.authClient.autoLogin() }
                    let outcome = await withTaskGroup(of: AutoLoginOutcome.self) { group in
                        group.addTask {
                            // 비구조적 Task의 value를 기다리는 쪽이 취소돼도 Task 자체는 취소되지 않는다.
                            .completed(await TaskResult { try await autoLoginTask.value })
                        }
                        group.addTask {
                            try? await self.clock.sleep(for: Self.maximumWaitDuration)
                            return .timedOut
                        }
                        let first = await group.next() ?? .timedOut
                        group.cancelAll()
                        return first
                    }
                    _ = try await splashDelay

                    switch outcome {
                    case let .completed(.success(authInfo)):
                        Log.trace("✅ Auto login check completed. AuthInfo: \(authInfo != nil)", category: .debug, level: .info)
                        await send(.delegate(.finishedLaunch(authInfo: authInfo)))
                    case let .completed(.failure(error)):
                        Log.trace("⚠️ Auto login failed: \(error)", category: .debug, level: .error)
                        await send(.delegate(.finishedLaunch(authInfo: nil)))
                    case .timedOut:
                        // 정책 문의 '자동 로그인 네트워크 실패 시 처리'(#21) 결정 전까지 네트워크 실패와 같게 처리한다.
                        // 저장된 토큰은 지우지 않는다(진행 중인 재발급이 끝나면 갱신됨).
                        Log.trace("⚠️ Auto login timed out after \(Self.maximumWaitDuration)", category: .debug, level: .error)
                        await send(.delegate(.finishedLaunch(authInfo: nil)))
                    }
                }
                .cancellable(id: CancelID.onAppearLaunch, cancelInFlight: true)

            case .alert(.presented(.goToUpdateTapped)):
                // TODO: - 추후 업데이트 로직 구현 필요
                return .none
                
            case .alert, .delegate, .view:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
