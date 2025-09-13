import ComposableArchitecture
import Foundation

@Reducer
public struct SplashFeature {
    public init() {}
    
    // MARK: - State & Action
    public struct State: Equatable {
        
    }
    
    public enum Action {
        // 뷰가 나타날 때 시작점으로 사용될 액션
        case onAppear
        
        // 각 비동기 작업의 결과를 처리할 내부 액션
        case _versionCheckResponse(TaskResult<Bool>) // Bool: isUpdateNeeded
        case _initialDataResponse(TaskResult<InitialDataResult>)
        
        // 부모 Reducer에게 결과를 전달하고 역할을 마치는 Delegate 액션
        public enum Delegate {
            case complete(SplashResult)
        }
        case delegate(Delegate)
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.appInfoClient) var appInfoClient
    @Dependency(\.authClient) var authClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await self.clock.sleep(for: .seconds(2))
                    
                    await send(._versionCheckResponse(
                        await TaskResult { try await self.appInfoClient.isUpdateNeeded() }
                    ))
                }
                
            case let ._versionCheckResponse(.success(isUpdateNeeded)):
                if isUpdateNeeded {
                    return .send(.delegate(.complete(.needsUpdate)))
                }
                
                return .run { send in
                    await send(._initialDataResponse(
                        await TaskResult { try await self.authClient.fetchInitialData() }
                    ))
                }
                
            case let ._initialDataResponse(.success(result)):
                switch result {
                case .needsOnboarding:
                    return .send(.delegate(.complete(.needsOnboarding)))
                case .loginSuccess:
                    return .send(.delegate(.complete(.loginSuccess)))
                case .loginFailure:
                    return .send(.delegate(.complete(.loginFailure)))
                }
                
            case ._versionCheckResponse(.failure), ._initialDataResponse(.failure):
                return .send(.delegate(.complete(.loginFailure)))
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Types
// 스플래쉬 로직 완료 후 결과 타입
public enum SplashResult {
    case needsUpdate
    case needsOnboarding
    case loginSuccess
    case loginFailure
}

// 첫 진입/자동 로그인 확인 결과 타입
public enum InitialDataResult {
    case needsOnboarding
    case loginSuccess
    case loginFailure
}
