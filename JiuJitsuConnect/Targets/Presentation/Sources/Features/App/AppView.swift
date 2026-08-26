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
        AppTabView(store: appTabStore)
      } else {
        EmptyView()
      }
    }
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
}
