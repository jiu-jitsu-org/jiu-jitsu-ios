import ComposableArchitecture
import Foundation

@Reducer
public struct AuthFeature {
    public enum State: Equatable {
        
    }
    
    public enum Action {

    }
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            return .none
        }
    }
}
