import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct SplashView: View {
    let store: StoreOf<SplashFeature>

    public init(store: StoreOf<SplashFeature>) {
        self.store = store
    }

    public var body: some View {
        // LaunchScreen.storyboard와 같은 이미지·같은 비율로 그린다.
        // 둘이 어긋나면 런치스크린 → 스플래시로 바뀌는 순간 그림이 움직인다.
        GeometryReader { proxy in
            let width = proxy.size.width
            let frameHeight = width * Metrics.frameAspect
            let frameTop = (proxy.size.height - frameHeight) / 2

            ZStack(alignment: .top) {
                Color.primitive.blue.b500p
                piece(Assets.Splash.pattern, width: width, top: frameTop + frameHeight * Metrics.patternTop)
                piece(Assets.Splash.tagline, width: width * Metrics.taglineWidth, top: frameTop + frameHeight * Metrics.taglineTop)
                piece(Assets.Splash.logo, width: width * Metrics.logoWidth, top: frameTop + frameHeight * Metrics.logoTop)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            store.send(.view(.onAppear))
        }
    }

    private func piece(_ asset: ImageAsset, width: CGFloat, top: CGFloat) -> some View {
        asset.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .offset(y: top)
    }
}

/// 시안 프레임(555×1200) 기준 비율. LaunchScreen.storyboard 제약 multiplier와 같은 값이어야 한다.
private enum Metrics {
    static let frameAspect: CGFloat = 1200 / 555
    static let patternTop: CGFloat = 0.1775
    static let taglineWidth: CGFloat = 0.477477
    static let taglineTop: CGFloat = 0.429167
    static let logoWidth: CGFloat = 0.488288
    static let logoTop: CGFloat = 0.465
}
