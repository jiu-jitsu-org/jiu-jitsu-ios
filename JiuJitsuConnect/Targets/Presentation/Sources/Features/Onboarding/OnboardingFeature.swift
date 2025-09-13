import ComposableArchitecture
import Foundation

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        
        public init() {}
    }
    
    public enum Action {

    }
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            return .none
        }
    }
}
