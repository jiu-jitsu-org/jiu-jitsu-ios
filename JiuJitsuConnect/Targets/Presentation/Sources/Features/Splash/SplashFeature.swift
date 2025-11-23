import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct SplashFeature {
    public init() {}

    @Dependency(\.continuousClock) var clock
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public init() {}
    }
    
    @CasePathable
    public enum Action: Equatable {
        case onAppear
        case didFinishInitLaunch
        case alert(PresentationAction<Alert>)
        
        public enum Alert: Equatable {
            case goToUpdateTapped
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.didFinishInitLaunch)
                }
                
            case .alert(.presented(.goToUpdateTapped)):
                // TODO: - 추후 업데이트 로직 구현 필요
                return .none
                
            default: return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
