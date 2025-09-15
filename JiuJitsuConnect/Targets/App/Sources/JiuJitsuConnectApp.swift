import SwiftUI
import ComposableArchitecture
import Presentation

@main
struct JiuJitsuConnectApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store<AppFeature.State, AppFeature.Action>(
              initialState: .init(),
              reducer: { AppFeature() }
            ))
        }
    }
}
