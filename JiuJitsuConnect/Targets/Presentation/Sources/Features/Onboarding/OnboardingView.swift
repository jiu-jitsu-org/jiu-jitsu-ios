import SwiftUI
import ComposableArchitecture

public struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            Text("Oss")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
        .onAppear {
//            store.send(.onAppear)
        }
    }
}
