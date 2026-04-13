import ComposableArchitecture
import CoreKit
import Foundation
import Domain

@Reducer
public struct SplashFeature: Sendable {
    public init() {}

    private enum CancelID: Hashable, Sendable {
        case onAppearLaunch
        case fcmSync
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient
    @Dependency(\.firebaseClient) var firebaseClient
    @Dependency(\.userClient) var userClient

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
                return .merge(
                    // FCM sync: 스플래시 라이프사이클과 무관하게 독립 실행
                    .run { _ in
                        await FCMAppInfoSync.syncOnAppLaunch(
                            firebaseClient: self.firebaseClient,
                            userClient: self.userClient
                        )
                    }
                    .cancellable(id: CancelID.fcmSync, cancelInFlight: true),
                    // 스플래시 최소 대기 + 자동 로그인 병렬 (취소 가능)
                    .run { send in
                        async let splashDelay: Void = self.clock.sleep(for: .seconds(1.5))
                        async let autoLoginResult = TaskResult {
                            try await self.authClient.autoLogin()
                        }

                        let loginResult = await autoLoginResult
                        _ = try await splashDelay

                        switch loginResult {
                        case let .success(authInfo):
                            Log.trace("✅ Auto login check completed. AuthInfo: \(authInfo != nil)", category: .debug, level: .info)
                            await send(.delegate(.finishedLaunch(authInfo: authInfo)))
                        case let .failure(error):
                            Log.trace("⚠️ Auto login failed: \(error)", category: .debug, level: .error)
                            await send(.delegate(.finishedLaunch(authInfo: nil)))
                        }
                    }
                    .cancellable(id: CancelID.onAppearLaunch, cancelInFlight: true)
                )

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
