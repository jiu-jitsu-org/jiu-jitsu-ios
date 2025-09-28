import Foundation
import ProjectDescription

public let version = "1.0.0"
public let deploymentTargetString = "26.0"
public let appDeploymentTargets: DeploymentTargets = .iOS(deploymentTargetString)
public let appDestinations: Destinations = [.iPhone, .iPad]
let isAppStore = Environment.isAppStore.getBoolean(default: false)
let additionalCondition = isAppStore ? "APPSTORE" : ""

// MARK: - SwiftLint
let swiftlintScript: TargetScript = .pre(
    script: """
    if which swiftlint >/dev/null; then
        swiftlint --fix && swiftlint
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
    settings: .settings(
        base: [
            "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
            "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: deploymentTargetString),
            "ENABLE_BITCODE": "NO",
            "CODE_SIGN_IDENTITY": "",
            "CODE_SIGNING_REQUIRED": "NO",
            "DEVELOPMENT_LANGUAGE": "ko"
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: .relativeToRoot("Configs/Secrets.xcconfig")),
            .release(name: "Release", xcconfig: .relativeToRoot("Configs/Secrets.xcconfig"))
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
            entitlements: "JiuJitsuConnect.entitlements",
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "Presentation"),
                .target(name: "Data")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "MARKETING_VERSION": SettingValue(stringLiteral: version),
                    "CODE_SIGN_IDENTITY": "iPhone Developer",
                    "CODE_SIGNING_REQUIRED": "YES",
                    "OTHER_LDFLAGS": "-ObjC",
                ],
                debug: [
                    "OTHER_SWIFT_FLAGS": "-D DEBUG $(inherited) -Xfrontend -warn-long-function-bodies=500 -Xfrontend -warn-long-expression-type-checking=500 -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking -Xfrontend -enable-actor-data-race-checks",
                    "OTHER_LDFLAGS": "-Xlinker -interposable $(inherited)",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition) DEBUG",
                ],
                release: [
                    "OTHER_LDFLAGS": "$(inherited)",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition)",
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
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
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
            product: Environment.forPreview.getBoolean(default: false) ? .framework : .staticFramework,
            bundleId: "com.jiujitsulab.connect.data",
            deploymentTargets: appDeploymentTargets,
            infoPlist: .default,
            sources: ["Targets/Data/Sources/**",
                      "Secrets/GoogleService-Info.plist"],
            scripts: [swiftlintScript],
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
            scripts: [swiftlintScript],
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
            scripts: [swiftlintScript],
            dependencies: [
                .target(name: "CoreKit")
            ]
        )
    ]
)
