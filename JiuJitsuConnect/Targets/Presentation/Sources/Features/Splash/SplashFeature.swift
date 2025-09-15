import ComposableArchitecture
import Foundation

@Reducer
public struct SplashFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        
        public init() {}
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
