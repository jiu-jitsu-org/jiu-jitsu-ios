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
        case didFinishInitLaunch // 스플레시 완료 - 첫 진입
        
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
                    try await self.clock.sleep(for: .seconds(2))
                    await send(.didFinishInitLaunch)
                }
                
            case .alert(.presented(.goToUpdateTapped)):
//                Utility.moveAppStore()
                return .none
                
            default: return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
