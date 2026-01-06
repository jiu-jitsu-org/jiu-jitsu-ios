import UIKit
import SwiftUI
import Combine
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
                .onShake {
                    self.isPulsePresented  = true
                }
                .sheet(isPresented: $isPulsePresented) {
                    NavigationView {
                        ConsoleView()
                    }
                }
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
                    $0.communityClient = DependencyContainer.shared.configureCommunityClient()
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
// 쉐이크 이벤트를 SwiftUI로 전달하기 위한 Notification 이름 정의
extension NSNotification.Name {
    static let deviceDidShake = NSNotification.Name("deviceDidShakeNotification")
}

// UIWindow를 서브클래싱하여 motionEnded 이벤트를 재정의
class ShakeDetectingWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // First Responder가 누구든 상관없이, 윈도우 레벨에서 이벤트를 먼저 받음
        if motion == .motionShake {
            // NotificationCenter를 통해 앱 전체에 쉐이크 이벤트를 방송
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        // 이벤트를 Responder Chain의 다음 객체로 전달하여 기본 동작을 유지
        super.motionEnded(motion, with: event)
    }
}

// SwiftUI 뷰에 적용하여 윈도우를 찾아 클래스를 교체하는 ViewModifier
struct ShakeObserverModifier: ViewModifier {
    // 한 번만 실행되도록 보장하기 위한 상태 변수
    @State private var isConfigured = false

    func body(content: Content) -> some View {
        // isConfigured가 false일 때만 아래 로직을 실행
        if !isConfigured {
            // content 뷰의 배경에 보이지 않는 뷰를 추가하여 window에 접근
            content.background(WindowFinder(isConfigured: $isConfigured))
        } else {
            // 설정이 완료되면 content만 반환
            content
        }
    }
}

// 실제 윈도우를 찾는 로직을 담은 UIViewRepresentable
private struct WindowFinder: UIViewRepresentable {
    @Binding var isConfigured: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // 뷰가 화면에 추가되는 시점을 기다리기 위해 투명하게 설정
        view.backgroundColor = .clear
        
        // 비동기적으로 메인 스레드에서 윈도우를 찾도록 예약
        DispatchQueue.main.async {
            // 이 뷰를 포함하는 UIWindow를 찾음
            guard let window = view.window else { return }
            
            // 윈도우의 클래스가 이미 우리가 만든 커스텀 클래스가 아니라면 교체
            if !(window is ShakeDetectingWindow) {
                // object_setClass를 사용하여 런타임에 윈도우의 클래스를 교체 (스위즐링과 유사)
                object_setClass(window, ShakeDetectingWindow.self)
            }
            
            // 설정 완료 플래그를 true로 변경
            self.isConfigured = true
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// .onShake(perform:)을 대체할 새로운 Modifier
extension View {
    func onShake(onShake: @escaping () -> Void) -> some View {
        // Notification을 Combine Publisher로 변환하여 수신
        self.onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            onShake()
        }
        // ShakeObserverModifier를 적용하여 윈도우 설정을 트리거
        .modifier(ShakeObserverModifier())
    }
}
