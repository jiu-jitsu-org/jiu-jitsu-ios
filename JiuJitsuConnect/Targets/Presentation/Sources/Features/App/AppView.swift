import SwiftUI
import ComposableArchitecture

@MainActor
public struct AppView: View {
  let store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  public var body: some View {
    if let splashStore = store.scope(state: \.destination?.splash, action: \.destination.splash) {
      SplashView(store: splashStore)
    } else if let loginStore = store.scope(state: \.destination?.login, action: \.destination.login) {
      LoginView(store: loginStore)
    } else if let appTabStore = store.scope(state: \.destination?.appTab, action: \.destination.appTab) {
      AppTabView(store: appTabStore)
    } else if let mainStore = store.scope(state: \.destination?.main, action: \.destination.main) {
      MainView(store: mainStore)
    } else {
      EmptyView()
    }
  }
}
