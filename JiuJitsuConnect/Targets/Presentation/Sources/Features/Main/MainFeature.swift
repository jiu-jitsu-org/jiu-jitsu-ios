import ComposableArchitecture
import Foundation

@Reducer
public struct MainFeature {
    public struct State: Equatable {
        var isLoggedIn: Bool
        
    }
    
    public enum Action {

    }
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            return .none
        }
    }
}
