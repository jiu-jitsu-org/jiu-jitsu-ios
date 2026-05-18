import SwiftUI
import ComposableArchitecture

public struct SplashView: View {
    let store: StoreOf<SplashFeature>
    
    public init(store: StoreOf<SplashFeature>) {
        self.store = store
    }
    
    public var body: some View {
        // LaunchScreen.storyboard와 동일한 외형 유지를 위해
        // 시스템 폰트/원색을 사용한다 (런치스크린은 커스텀 폰트/토큰 로드 불가).
        GeometryReader { proxy in
            ZStack {
                Color.white
                Text("OSS")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.black)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 3)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            store.send(.view(.onAppear))
        }
    }
}
