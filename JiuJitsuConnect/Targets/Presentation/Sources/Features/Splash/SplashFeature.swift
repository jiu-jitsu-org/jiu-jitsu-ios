import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct SplashFeature: Sendable {
    public init() {}

    @Dependency(\.continuousClock) var clock
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Alert>?
        
        public init() {}
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        
        public enum ViewAction: Sendable {
            case onAppear
        }
        
        public enum InternalAction: Sendable {
            case didFinishInitLaunch
        }
        
        public enum DelegateAction: Sendable {
            case finishedLaunch
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
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.didFinishInitLaunch))
                }
                
            case .internal(.didFinishInitLaunch):
                return .send(.delegate(.finishedLaunch))
                
            case .alert(.presented(.goToUpdateTapped)):
                // TODO: - 추후 업데이트 로직 구현 필요
                return .none
                
            case .alert, .delegate, .view, .internal:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
