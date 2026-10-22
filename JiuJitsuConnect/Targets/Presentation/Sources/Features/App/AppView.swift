import SwiftUI
import ComposableArchitecture
import Foundation

@MainActor
public struct AppView: View {
  let store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  public var body: some View {
    Group {
      if let splashStore = store.scope(state: \.destination?.splash, action: \.destination.splash) {
        SplashView(store: splashStore)
      } else if let loginStore = store.scope(state: \.destination?.login, action: \.destination.login) {
        LoginView(store: loginStore)
      } else if let appTabStore = store.scope(state: \.destination?.appTab, action: \.destination.appTab) {
        // 홈은 인사 장면이 있든 없든 같은 자리에 두어, 인사가 끝나도 화면이 다시 만들어지지 않게 한다
        ZStack {
          if store.greeting != nil {
            GreetingSceneView(
              onCover: { store.send(.view(.greetingCoverStarted), animation: Self.coverAnimation) },
              onFinish: { store.send(.view(.greetingFinished)) }
            )
          }
          AppTabView(store: appTabStore)
            .modifier(GreetingCover(isHidden: store.greeting == .playing, isActive: store.greeting != nil))
        }
      } else {
        EmptyView()
      }
    }
    // 푸시 탭 릴레이 구독 시작. 유니버설 링크 수신과 같은 이유로 분기 바깥(Group)에 붙인다.
    .onAppear { store.send(.view(.onAppear)) }
    // 유니버설 링크(공유 링크) 수신 창구. 화면 전환과 무관하게 항상 살아 있어야 해
    // 분기 바깥(Group)에 붙인다.
    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
      guard let url = activity.webpageURL else { return }
      store.send(.view(.deepLinkReceived(url)))
    }
    // SwiftUI는 유니버설 링크를 onOpenURL로도 전달할 수 있어 같은 액션을 한 번 더 받아둔다.
    // 두 경로가 모두 발화해도 CommunityFeature가 최상단 중복 상세를 걸러낸다.
    // (카카오·구글 커스텀 스킴은 여기서 파싱에 실패해 그대로 무시되고, App 타겟의 onOpenURL이 처리한다)
    .onOpenURL { url in
      store.send(.view(.deepLinkReceived(url)))
    }
  }

  /// 홈이 아래에서 올라와 덮는 움직임 (시안 cubic-bezier(.6, 0, .2, 1), 0.52초)
  private static let coverAnimation = Animation.timingCurve(0.6, 0, 0.2, 1, duration: 0.52)
}

/// 인사 장면 위로 홈을 덮어 올린다. 숨어 있을 때는 화면 아래로 내려 두고, 위쪽 모서리를 둥글게 깎는다.
/// 인사가 끝나면(`isActive == false`) 깎지 않아 홈이 안전 영역까지 그대로 그려진다.
private struct GreetingCover: ViewModifier {
  let isHidden: Bool
  let isActive: Bool

  @State private var travel: CGFloat = 0
  @State private var topInset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .clipShape(TopRoundedCover(radius: isHidden ? 28 : 0, topInset: topInset, isActive: isActive))
      .offset(y: isHidden ? travel : 0)
      .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { insets in
        topInset = insets.top
      }
      .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } action: { height in
        travel = height
      }
  }
}

/// 위쪽 두 모서리만 둥근 덮개 모양. 홈이 안전 영역(상태 막대 자리)까지 그리므로 그만큼 위로 넓힌다.
private struct TopRoundedCover: Shape {
  var radius: CGFloat
  let topInset: CGFloat
  let isActive: Bool

  var animatableData: CGFloat {
    get { radius }
    set { radius = newValue }
  }

  func path(in rect: CGRect) -> Path {
    // 아래와 양옆은 넉넉히 넓혀 탭 바·홈 바 자리 그림이 잘리지 않게 한다
    let bounds = CGRect(x: rect.minX - 200, y: rect.minY - topInset, width: rect.width + 400, height: rect.height + topInset + 400)
    guard isActive else { return Path(bounds.insetBy(dx: -2000, dy: -2000)) }
    let cover = CGRect(x: rect.minX, y: bounds.minY, width: rect.width, height: bounds.height)
    return UnevenRoundedRectangle(topLeadingRadius: radius, topTrailingRadius: radius).path(in: cover)
  }
}
