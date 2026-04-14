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
