import ComposableArchitecture
import CoreKit
import Foundation
import Domain

@Reducer
public struct SplashFeature: Sendable {
    public init() {}

    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient
    
    @ObservableState
    public struct State: Equatable {
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
        Reduce { _, action in
            switch action {
            case .view(.onAppear):
                return .run { send in
                    // 최소 스플래시 표시 시간과 자동 로그인을 병렬로 실행
                    async let splashDelay: Void = self.clock.sleep(for: .seconds(1.5))
                    async let autoLoginResult = TaskResult { 
                        try await self.authClient.autoLogin() 
                    }
                    
                    // 두 작업 모두 완료될 때까지 대기
                    _ = try await splashDelay
                    let result = await autoLoginResult
                    
                    // 결과 처리
                    switch result {
                    case let .success(authInfo):
                        Log.trace("Auto login check completed. AuthInfo: \(authInfo != nil)", category: .debug, level: .info)
                        await send(.delegate(.finishedLaunch(authInfo: authInfo)))
                        
                    case let .failure(error):
                        Log.trace("Auto login failed: \(error)", category: .debug, level: .error)
                        await send(.delegate(.finishedLaunch(authInfo: nil)))
                    }
                }
                
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
