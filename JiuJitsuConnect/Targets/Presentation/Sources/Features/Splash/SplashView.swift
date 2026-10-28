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
            let layout = SplashLayout(size: proxy.size)

            ZStack(alignment: .top) {
                Color.primitive.blue.b500p
                piece(Assets.Splash.pattern, width: layout.patternWidth, top: layout.patternTop)
                piece(Assets.Splash.tagline, width: layout.taglineWidth, top: layout.taglineTop)
                piece(Assets.Splash.logo, width: layout.logoWidth, top: layout.logoTop)
            }
        }
        .ignoresSafeArea()
        .lightStatusBar()
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

/// 스플래시 한 장면의 배치. 시안 프레임(555×1200)을 화면 폭에 맞춰 키우고 세로 가운데에 둔 뒤, 조각을 그 프레임 기준 비율로 놓는다.
///
/// 로그인·인사 장면도 이 모습에서 시작하므로 같은 값을 쓴다. 비율은 LaunchScreen.storyboard 제약 multiplier와 같아야 한다.
struct SplashLayout {
    let patternWidth: CGFloat
    let patternTop: CGFloat
    let taglineWidth: CGFloat
    let taglineTop: CGFloat
    let logoWidth: CGFloat
    let logoTop: CGFloat

    init(size: CGSize) {
        let frameHeight = size.width * Ratio.frameAspect
        let frameTop = (size.height - frameHeight) / 2
        // 둥근 그래픽은 그림 양옆이 잘려 있어 화면 폭보다 좁히면 잘린 자리가 드러난다. 그래서 폭은 그대로 둔다
        patternWidth = size.width
        patternTop = frameTop + frameHeight * Ratio.patternTop
        taglineWidth = size.width * Ratio.taglineWidth
        taglineTop = frameTop + frameHeight * Ratio.taglineTop
        logoWidth = size.width * Ratio.logoWidth
        logoTop = frameTop + frameHeight * Ratio.logoTop
    }

    /// 문구·OSS 글자는 처음 시안보다 0.85배로 줄였다(#111). 두 글자 묶음의 세로 가운데(프레임 48.79%)는 그대로 두고 줄인 값이다
    private enum Ratio {
        static let frameAspect: CGFloat = 1200 / 555
        static let patternTop: CGFloat = 0.1775
        static let taglineWidth: CGFloat = 0.405855
        static let taglineTop: CGFloat = 0.437979
        static let logoWidth: CGFloat = 0.415045
        static let logoTop: CGFloat = 0.468438
    }
}
