import SwiftUI
import ComposableArchitecture

@MainActor
public struct AppView: View {
  let store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  public var body: some View {
    switch store.state.destination {
    case .splash:
      if let splashStore = store.scope(state: \.destination?.splash, action: \.destination.splash) {
        SplashView(store: splashStore)
      }
      
    case .onboarding:
      if let onboardingStore = store.scope(state: \.destination?.onboarding, action: \.destination.onboarding) {
        OnboardingView(store: onboardingStore)
      }
      
    case .main:
      if let mainStore = store.scope(state: \.destination?.main, action: \.destination.main) {
        MainView(store: mainStore)
      }
      
    case .login:
      if let loginStore = store.scope(state: \.destination?.login, action: \.destination.login) {
        LoginView(store: loginStore)
      }
    case .none:
      EmptyView()
        
    case .some:
        EmptyView()

    }
  }
}
