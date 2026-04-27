import SwiftUI
import ComposableArchitecture

// TODO: - 실제 구현으로 교체 필요
public struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    public init(store: StoreOf<CommunityFeature>) { self.store = store }
    public var body: some View { Text("홈 화면") }
}
