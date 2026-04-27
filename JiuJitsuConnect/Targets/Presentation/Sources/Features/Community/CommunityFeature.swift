import ComposableArchitecture

// TODO: - 실제 구현으로 교체 필요
@Reducer
public struct CommunityFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable { public init() {} }
    
    public enum Action: Sendable {}
    
    public var body: some ReducerOf<Self> { EmptyReducer() }
}
