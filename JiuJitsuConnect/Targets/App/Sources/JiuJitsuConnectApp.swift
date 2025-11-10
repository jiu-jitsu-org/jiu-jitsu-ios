import SwiftUI
import ComposableArchitecture
import Presentation
import GoogleSignIn
import KakaoSDKCommon
import KakaoSDKAuth
import PulseUI

@main
struct JiuJitsuConnectApp: App {
    init() {
        configureGoogleSignIn()
        configureKakaoSDK()
    }
    
    @State private var isPulsePresented = false
    
    var body: some Scene {
        WindowGroup {
            AppView(store: createStore())
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    } else {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
                #if DEBUG
                .onShake {
                    self.isPulsePresented  = true
                }
                .sheet(isPresented: $isPulsePresented) {
                    NavigationView {
                        ConsoleView()
                    }
                }
                #endif
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
    
    private func configureKakaoSDK() {
        // Info.plist에서 KAKAO_NATIVE_APP_KEY 값을 가져와 초기화
        guard let kakaoAppKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String else {
            fatalError("KAKAO_NATIVE_APP_KEY is not set in Info.plist")
        }
        KakaoSDK.initSDK(appKey: kakaoAppKey)
    }
    
    // Store 생성 함수
    private func createStore() -> StoreOf<AppFeature> {
        // 테스트 환경이 아닐 때만 Live 의존성 주입
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            return Store(
                initialState: AppFeature.State(),
                reducer: { AppFeature() },
                withDependencies: {
                    $0.authClient = DependencyContainer.shared.configureAuthClient()
                    $0.userClient = DependencyContainer.shared.configureUserClient()
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

// TODO: - Clean Architecture에 코드 위치 수정
// MARK: - DEBUG 전용 HAND SHAKE LOG VIEW (수정된 최종 버전)

// 1. UIResponder 이벤트를 직접 처리하는 UIView 서브클래스 생성
private class ShakeEnabledView: UIView {
    // 흔들기 이벤트가 감지되면 실행될 클로저
    var onShake: () -> Void = {}

    // 이 뷰가 First Responder가 될 수 있음을 시스템에 알립니다. (매우 중요!)
    override var canBecomeFirstResponder: Bool {
        true
    }

    // 뷰가 윈도우에 추가된 후 First Responder가 되도록 요청합니다.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }

    // 쉐이크 모션이 끝났을 때 이 메서드가 호출됩니다.
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // 쉐이크가 감지되면 클로저를 실행합니다.
            onShake()
        }
        // 상위 클래스의 메서드도 호출해주는 것이 좋습니다.
        super.motionEnded(motion, with: event)
    }
}

// 2. 위에서 만든 ShakeEnabledView를 SwiftUI에서 사용하도록 래핑
private struct ShakeDetectorView: UIViewRepresentable {
    var onShake: () -> Void

    func makeUIView(context: Context) -> ShakeEnabledView {
        let view = ShakeEnabledView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ uiView: ShakeEnabledView, context: Context) {}
}

private struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ShakeDetectorView(onShake: action))
    }
}

public extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}
