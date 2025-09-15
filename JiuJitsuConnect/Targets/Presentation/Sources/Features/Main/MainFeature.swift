import ComposableArchitecture
import Foundation

@Reducer
public struct MainFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        
    }
    
    @CasePathable
    public enum Action: Equatable {

    }
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            return .none
        }
    }
}
