import SwiftUI
import ComposableArchitecture

public struct SplashView: View {
    let store: StoreOf<SplashFeature>
    
    public init(store: StoreOf<SplashFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            // TODO: 스플래쉬 배경 및 로고 이미지 추가
            Color.blue.ignoresSafeArea()
            Text("Oss")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
        .onAppear {
            store.send(.view(.onAppear))
        }
    }
}
