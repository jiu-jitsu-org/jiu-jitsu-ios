import Foundation
import ProjectDescription

public let version = "1.0.0"
public let deploymentTargetString = "17.0"
public let appDeploymentTargets: DeploymentTargets = .iOS(deploymentTargetString)
public let appDestinations: Destinations = [.iPhone, .iPad]
let isAppStore = Environment.isAppStore.getBoolean(default: false)

// MARK: - SwiftLint
let swiftlintScript: TargetScript = .pre(
    script: """
  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  """,
    name: "SwiftLint",
    basedOnDependencyAnalysis: false
)

// MARK: - Info Plist
let appInfoPlist: [String: Plist.Value] = {
    var base: [String: Plist.Value] = [
        "CFBundleDisplayName": "JiuJitsuLab",
        "CFBundleShortVersionString": Plist.Value(stringLiteral: version),
        "UILaunchStoryboardName": "Launch Screen",
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
        "UISupportedInterfaceOrientations~ipad": [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ],
        "UIAppFonts": [
            "Pretendard-Black.otf",
            "Pretendard-Bold.otf",
            "Pretendard-ExtraBold.otf",
            "Pretendard-ExtraLight.otf",
            "Pretendard-Light.otf",
            "Pretendard-Medium.otf",
            "Pretendard-Regular.otf",
            "Pretendard-SemiBold.otf",
            "Pretendard-Thin.otf"
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
        "BASE_URL": "$(BASE_URL)",
        "TEST_BASE_URL": "$(TEST_BASE_URL)",
        "LSApplicationQueriesSchemes": [
            "kakaokompassauth",
            "kakaolink"
        ]
    ]
    return base
}()

// MARK: - Project
let project = Project(
    name: "JiuJitsuConnect",
    targets: [
        // MARK: - App Target (Executable)
        .target(
            name: "App",
            destinations: appDestinations,
            product: .app,
            bundleId: "com.jiujitsulab.connect",
            sources: ["Targets/App/Sources/**"],
            resources: ["Targets/App/Resources/**"],
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "Presentation")
            ]
        ),
        
        // MARK: - Presentation Target (UI & State Management)
        .target(
            name: "Presentation",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.presentation",
            sources: ["Targets/Presentation/Sources/**"],
            resources: ["Targets/Presentation/Resources/**"],
            scripts: [swiftlintScript],
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
            sources: ["Targets/Domain/Sources/**"],
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "CoreKit")
            ]
        ),
        
        // MARK: - Data Target (Data Handling)
        .target(
            name: "Data",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.data",
            sources: ["Targets/Data/Sources/**"],
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "CoreKit"),
                .package(product: "KakaoSDKCommon"),
                .package(product: "KakaoSDKAuth"),
                .package(product: "KakaoSDKUser"),
                .package(product: "GoogleSignIn"),
                .package(product: "GoogleSignInSwift")
            ]
        ),
        
        // MARK: - CoreKit Target (Shared Non-UI Modules)
        .target(
            name: "CoreKit",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.corekit",
            sources: ["Targets/CoreKit/Sources/**"],
            scripts: [swiftlintScript],
            dependencies: []
        ),
        
        // MARK: - DesignSystem Target (Shared UI Modules)
        .target(
            name: "DesignSystem",
            destinations: appDestinations,
            product: .framework,
            bundleId: "com.jiujitsulab.connect.designsystem",
            sources: ["Targets/DesignSystem/Sources/**"],
            resources: ["Targets/DesignSystem/Resources/**"],
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "CoreKit")
            ]
        )
    ]
)
