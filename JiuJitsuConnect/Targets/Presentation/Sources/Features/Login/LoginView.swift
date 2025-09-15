import SwiftUI
import ComposableArchitecture

public struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            Text("JiuJitsuConnect")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
        .onAppear {
//            store.send(.onAppear)
        }
    }
}
