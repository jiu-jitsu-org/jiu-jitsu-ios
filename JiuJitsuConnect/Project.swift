import Foundation
import ProjectDescription

public let version = "1.0.0"
public let deploymentTargetString = "26.0"
public let appDeploymentTargets: DeploymentTargets = .iOS(deploymentTargetString)
public let appDestinations: Destinations = [.iPhone]
let isAppStore = Environment.isAppStore.getBoolean(default: false)
let additionalCondition = isAppStore ? "APPSTORE" : ""

// MARK: - SwiftLint (스킴 `SwiftLint`로만 실행 — 일반 앱 빌드에서는 스크립트 미실행)
let swiftlintScript: TargetScript = .pre(
    script: """
    cd "${PROJECT_DIR}"
    if test -d "/opt/homebrew/bin/"; then
        export PATH="/opt/homebrew/bin/:${PATH}"
    fi
    if which swiftlint > /dev/null; then
        swiftlint
    else
        echo "warning: SwiftLint not installed, run: brew install swiftlint"
    fi
    """,
    name: "SwiftLint",
    basedOnDependencyAnalysis: false
)

// MARK: - Info Plist
let appInfoPlist: [String: Plist.Value] = {
    var base: [String: Plist.Value] = [
        "CFBundleDisplayName": "Oss",
        "CFBundleShortVersionString": Plist.Value(stringLiteral: version),
        "UILaunchStoryboardName": "LaunchScreen",
        "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": []
        ],
        "CFBundleDevelopmentRegion": "ko",
        "CFBundleLocalizations": [
            "ko"
        ],
        "ITSAppUsesNonExemptEncryption": false,
        "UIUserInterfaceStyle": "Light",
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],

        "UIAppFonts": [
            "Pretendard-Black.otf",
            "Pretendard-Bold.otf",
            "Pretendard-ExtraBold.otf",
            "Pretendard-ExtraLight.otf",
            "Pretendard-Light.otf",
            "Pretendard-Medium.otf",
            "Pretendard-Regular.otf",
            "Pretendard-SemiBold.otf",
            "Pretendard-Thin.otf",
            "CookieRun Black.otf",
            "CookieRun Bold.otf",
            "CookieRun Regular.otf"
        ],
        "CFBundleURLTypes": [
            [
                "CFBundleURLSchemes": ["com.googleusercontent.apps.$(GOOGLE_CLIENT_ID)"]
            ],
            [
                "CFBundleURLSchemes": ["kakao$(KAKAO_NATIVE_APP_KEY)"]
            ]
        ],
        "KAKAO_NATIVE_APP_KEY": "$(KAKAO_NATIVE_APP_KEY)",
        "GoogleSignIn": "$(GOOGLE_SIGN_IN)",
        // 실제 값은 구성별로 BASE_URL_DEV / BASE_URL_PROD 중 하나가 주입된다(아래 configurations 참고).
        "BASE_URL": "$(BASE_URL)",
        "WEB_URL": "$(WEB_URL)",
        // 테스트용 서버 전환(운영/개발) 다이얼로그가 읽는 후보 도메인.
        // Debug/Beta 구성에만 값이 정의돼 있고, Release에서는 빈 문자열로 치환된다.
        "DEBUG_WEB_URL_DEV": "$(DEBUG_WEB_URL_DEV)",
        "DEBUG_WEB_URL_PROD": "$(DEBUG_WEB_URL_PROD)",
        "IMAGEKIT_PUBLIC_KEY": "$(IMAGEKIT_PUBLIC_KEY)",
        // 테스트용 커뮤니티 웹뷰 도메인 변경(IP/HTTP) 지원을 위한 ATS 예외.
        // - NSAllowsArbitraryLoadsInWebContent: WKWebView가 임의 http(IP 포함)를 로드 가능.
        // - NSAllowsLocalNetworking: LAN/사설망(192.168.x, 172.16~31.x 등) 및 .local 접근 허용.
        // 네이티브 API 통신은 이 키들의 영향을 받지 않고 여전히 ATS(https)로 보호된다.
        // 도메인 변경 진입 버튼은 DEBUG/BETA 빌드에서만 노출되므로 릴리즈 실사용 노출은 없다.
        "NSAppTransportSecurity": [
            "NSAllowsArbitraryLoadsInWebContent": true,
            "NSAllowsLocalNetworking": true,
        ],
        "LSApplicationQueriesSchemes": [
            "kakaokompassauth",
            "kakaolink"
        ],
        "UIBackgroundModes": [
            "remote-notification"
        ],
        "FirebaseAppDelegateProxyEnabled": false,
        // 프로필 이미지 수정 + 커뮤니티 글 작성 웹뷰(<input type=file>) — 카메라 촬영
        "NSCameraUsageDescription": "사진을 촬영하기 위해 카메라를 사용합니다.",
        // 기능상 필수는 아님(PHPicker/웹뷰 파일 입력은 권한 프롬프트 없이 동작)이나
        // 보관함 접근 안내 일관성을 위해 명시.
        "NSPhotoLibraryUsageDescription": "사진을 첨부하기 위해 사진 보관함에 접근합니다.",
    ]
    return base
}()

// MARK: - Project
let project = Project(
    name: "JiuJitsuConnect",
    settings: .settings(
        base: [
            "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
            "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
            // TCA `@Reducer enum`이 생성하는 public CaseScope는 Sendable이 추론되지 않아
            // AnyCasePath(embed:)에서 non-Sendable 변환 경고가 난다(TCA #3897/#3958).
            // Warnings as Errors와 겹쳐 빌드가 깨지므로 SE-0418 추론을 켠다.
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: deploymentTargetString),
            "ENABLE_BITCODE": "NO",
            "CODE_SIGN_IDENTITY": "",
            "CODE_SIGNING_REQUIRED": "NO",
            "DEVELOPMENT_LANGUAGE": "ko"
        ],
        // 서버는 dev(develop 브랜치) / prod(main 브랜치) 2벌로 운영된다.
        // Beta는 사내 QA용이므로 Debug와 함께 dev를 바라보고, Release만 prod를 쓴다.
        // 값 자체는 Secrets.xcconfig의 *_DEV / *_PROD에 있고 여기서 BASE_URL·WEB_URL로 확정한다.
        configurations: [
            .debug(name: "Debug", settings: [
                "BASE_URL": "$(BASE_URL_DEV)",
                "WEB_URL": "$(WEB_URL_DEV)",
                "DEBUG_WEB_URL_DEV": "$(WEB_URL_DEV)",
                "DEBUG_WEB_URL_PROD": "$(WEB_URL_PROD)"
            ], xcconfig: .relativeToRoot("Configs/Secrets.xcconfig")),
            .release(name: "Beta", settings: [
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "BETA",
                "BASE_URL": "$(BASE_URL_DEV)",
                "WEB_URL": "$(WEB_URL_DEV)",
                "DEBUG_WEB_URL_DEV": "$(WEB_URL_DEV)",
                "DEBUG_WEB_URL_PROD": "$(WEB_URL_PROD)"
            ], xcconfig: .relativeToRoot("Configs/Secrets.xcconfig")),
            .release(name: "Release", settings: [
                "BASE_URL": "$(BASE_URL_PROD)",
                "WEB_URL": "$(WEB_URL_PROD)"
            ], xcconfig: .relativeToRoot("Configs/Secrets.xcconfig"))
        ]
    ),
    targets: [
        // MARK: - App Target (Executable)
        .target(
            name: "App",
            destinations: appDestinations,
            product: .app,
            bundleId: "com.jiujitsulab.connect",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .extendingDefault(with: appInfoPlist),
            sources: ["Targets/App/Sources/**"],
            resources: [
                "Targets/App/Resources/**",
                "Secrets/GoogleService-Info.plist",
                .glob(pattern: .relativeToRoot("Targets/DesignSystem/Resources/**"))
            ],
            dependencies: [
                .target(name: "Presentation"),
                .target(name: "Data"),
                .target(name: "CoreKit"),
                .external(name: "Pulse"),
                .external(name: "PulseUI"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
                .external(name: "GoogleSignIn")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "$(DEVELOPMENT_TEAM)",
                    "MARKETING_VERSION": SettingValue(stringLiteral: version),
                    "CODE_SIGN_IDENTITY": "iPhone Developer",
                    "CODE_SIGNING_REQUIRED": "YES",
                    "OTHER_LDFLAGS": "-ObjC",
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
                ],
                configurations: [
                    .debug(name: "Debug", settings: [
                        "OTHER_SWIFT_FLAGS": "-D DEBUG $(inherited) -Xfrontend -warn-long-function-bodies=500 -Xfrontend -warn-long-expression-type-checking=500 -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking -Xfrontend -enable-actor-data-race-checks",
                        "OTHER_LDFLAGS": "$(inherited)",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition) DEBUG",
                        "CODE_SIGN_ENTITLEMENTS": "JiuJitsuConnect.entitlements",
                    ]),
                    .release(name: "Beta", settings: [
                        "OTHER_LDFLAGS": "$(inherited)",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition) BETA",
                        "CODE_SIGN_ENTITLEMENTS": "JiuJitsuConnect.Release.entitlements",
                    ]),
                    .release(name: "Release", settings: [
                        "OTHER_LDFLAGS": "$(inherited)",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition)",
                        "CODE_SIGN_ENTITLEMENTS": "JiuJitsuConnect.Release.entitlements",
                    ]),
                ]
            )
        ),
        
        // MARK: - Presentation Target (UI & State Management)
        .target(
            name: "Presentation",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.presentation",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/Presentation/Sources/**"],
            resources: ["Targets/Presentation/Resources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "DesignSystem"),
                .external(name: "ComposableArchitecture")
            ]
        ),
        
        // MARK: - Domain Target (Business Logic)
        .target(
            name: "Domain",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.domain",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/Domain/Sources/**"],
            dependencies: [
                .target(name: "CoreKit")
            ]
        ),
        
        // MARK: - Data Target (Data Handling)
        .target(
            name: "Data",
            destinations: appDestinations,
            product: Environment.forPreview.getBoolean(default: false) ? .framework : .staticFramework,
            bundleId: "com.jiujitsulab.connect.data",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/Data/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "CoreKit"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKUser"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift")
            ]
        ),
        
        // MARK: - CoreKit Target (Shared Non-UI Modules)
        .target(
            name: "CoreKit",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.corekit",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/CoreKit/Sources/**"],
            dependencies: []
        ),
        
        // MARK: - DesignSystem Target (Shared UI Modules)
        .target(
            name: "DesignSystem",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.designsystem",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/DesignSystem/Sources/**"],
            resources: ["Targets/DesignSystem/Resources/**"],
            dependencies: [
                .target(name: "CoreKit"),
                .external(name: "Lottie")
            ]
        ),
        
        // MARK: - SwiftLint (스킴 전용, 앱에 링크되지 않음)
        .target(
            name: "SwiftLint",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.swiftlint",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/SwiftLint/Sources/**"],
            scripts: [swiftlintScript],
            dependencies: []
        )
    ],
    schemes: [
        .scheme(
            name: "App-Beta",
            shared: true,
            buildAction: .buildAction(targets: [.target("App")]),
            runAction: .runAction(configuration: "Beta"),
            archiveAction: .archiveAction(configuration: "Beta")
        ),
        .scheme(
            name: "SwiftLint",
            shared: true,
            buildAction: .buildAction(targets: [.target("SwiftLint")])
        )
    ]
)
