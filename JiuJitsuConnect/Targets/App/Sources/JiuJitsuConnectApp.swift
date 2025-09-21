import SwiftUI
import ComposableArchitecture
import Presentation
import GoogleSignIn

@main
struct JiuJitsuConnectApp: App {
    init() {
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: createStore())
        }
    }
    
    // MARK: - Configuration
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let clientId = NSDictionary(contentsOfFile: path)?["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    // ✅ Store 생성 함수
    private func createStore() -> StoreOf<AppFeature> {
        // 테스트 환경이 아닐 때만 Live 의존성 주입
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            return Store(
                initialState: AppFeature.State(),
                reducer: { AppFeature() },
                withDependencies: {
                    $0.authClient = DependencyContainer.shared.configureAuthClient()
                }
            )
        } else {
            // 테스트 환경에서는 기본 testValue 사용
            return Store(
                initialState: AppFeature.State(),
                reducer: { AppFeature() }
            )
        }
    }
}
