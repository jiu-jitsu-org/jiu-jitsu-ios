import Foundation
import ProjectDescription

public let version = "1.0.0"
public let deploymentTargetString = "26.0"
public let appDeploymentTargets: DeploymentTargets = .iOS(deploymentTargetString)
public let appDestinations: Destinations = [.iPhone]
let isAppStore = Environment.isAppStore.getBoolean(default: false)
let additionalCondition = isAppStore ? "APPSTORE" : ""

// MARK: - Release Info.plist (#353)
// 테스트용 ATS 예외(NSAppTransportSecurity)는 Debug·Beta 서버 전환에만 쓰므로 Release 빌드 결과에서 지운다.
// Info.plist 값을 빌드 변수로 바꾸면 불리언이 문자열로 들어가 ATS가 읽지 못할 수 있어 빌드 뒤 PlistBuddy로 지운다.
let releaseInfoPlistScript: TargetScript = .post(
    script: """
    if [ "${CONFIGURATION}" = "Release" ]; then
        /usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}" || true
    fi
    """,
    name: "Remove Test ATS Exceptions (Release)",
    inputPaths: ["$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"],
    basedOnDependencyAnalysis: false
)

// MARK: - Firebase 설정 파일 (#423)
// Debug · Beta는 dev 프로젝트(oss-bjj-dev), Release는 운영 프로젝트로 기록한다. 앱 안 이름은 SDK가 찾는
// `GoogleService-Info.plist` 하나로 같게 넣는다. 파일이 없으면 다른 프로젝트로 조용히 섞이지 않게 빌드를 멈춘다.
// Crashlytics dSYM 업로드가 이 결과를 읽으므로 그 스크립트보다 앞에 둔다.
let firebaseConfigScript: TargetScript = .pre(
    script: """
    if [ "${CONFIGURATION}" = "Release" ]; then
        SRC="${SRCROOT}/Secrets/GoogleService-Info.plist"
    else
        SRC="${SRCROOT}/Secrets/GoogleService-Info-Dev.plist"
    fi
    if [ ! -f "${SRC}" ]; then
        echo "error: ${SRC} 가 없습니다 — Firebase 콘솔(Debug · Beta: OSS-BJJ-dev, Release: 운영)에서 받아 Secrets/에 넣어 주세요"
        exit 1
    fi
    mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
    cp "${SRC}" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
    """,
    name: "Copy GoogleService-Info.plist",
    outputPaths: ["$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist"],
    basedOnDependencyAnalysis: false
)

// MARK: - Crashlytics dSYM 업로드 (#374)
// 아카이브(로컬 · Xcode Cloud)에서만 올린다. 일반 빌드마다 올리면 확인용 Release 빌드도 콘솔에 섞인다.
// Firebase 기본 `run`은 앱 dSYM만 올리는데, 앱 코드 대부분이 동적 framework(Presentation 등)에 있어
// 같은 폴더의 dSYM을 모두 올린다. 망이 없어도 아카이브는 막지 않는다.
let crashlyticsDSYMUploadScript: TargetScript = .post(
    script: """
    if [ "${ACTION}" != "install" ] || [ "${CONFIGURATION}" = "Debug" ]; then
        exit 0
    fi
    "${SRCROOT}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" \\
        -gsp "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist" \\
        -p ios "${DWARF_DSYM_FOLDER_PATH}" \\
        || echo "warning: Crashlytics dSYM 업로드 실패 — Firebase 콘솔에서 수동 업로드 필요"
    """,
    name: "Upload dSYMs to Crashlytics",
    inputPaths: [
        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
        "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
    ],
    basedOnDependencyAnalysis: false
)

// MARK: - 오픈소스 라이선스 고지 (#371)
// 목록(Targets/App/Resources/Settings.bundle)은 커밋된 결과를 쓴다. 패키지 · 설정이 바뀌어 낡았으면
// LicensePlist가 있는 기기에서는 다시 만들고(결과를 커밋), 없으면(Xcode Cloud 등) 경고만 남기고 빌드는 그대로 간다.
let licensesScript: TargetScript = .pre(
    script: """
    cd "${SRCROOT}"
    if [ "$(sh scripts/update-licenses.sh --hash)" = "$(cat Licenses/inputs.sha256 2>/dev/null)" ]; then
        exit 0
    fi
    sh scripts/update-licenses.sh \\
        || echo "warning: 오픈소스 라이선스 목록이 패키지와 다릅니다 — scripts/update-licenses.sh 실행 후 커밋"
    """,
    name: "Update Open Source Licenses",
    basedOnDependencyAnalysis: false
)

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
        "CFBundleDisplayName": "OSS",
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
        // 런치스크린이 파란 바탕이라 시계·배터리 글자를 흰색으로 시작한다. 이후 화면은 각 화면이 정한다
        "UIStatusBarStyle": "UIStatusBarStyleLightContent",
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],

        "UIAppFonts": [
            "Pretendard-Medium.otf",
            "Pretendard-SemiBold.otf",
            "CookieRun Black.otf"
        ],
        "CFBundleURLTypes": [
            [
                "CFBundleURLSchemes": ["com.googleusercontent.apps.$(GOOGLE_CLIENT_ID)"]
            ],
            [
                "CFBundleURLSchemes": ["kakao$(KAKAO_NATIVE_APP_KEY)"]
            ],
            // 웹 페이지 안의 '앱 열기' 버튼 진입용.
            // iOS는 같은 도메인 페이지에서 탭한 링크로 유니버설 링크를 발동시키지 않아
            // 그 버튼은 이 경로로만 앱을 열 수 있다(FE#72 실측).
            // 구성별로 나누지 않는다 — 번들 id가 Debug·Beta·Release 모두 같아 한 기기에 공존할 수 없다.
            [
                "CFBundleURLName": "com.jiujitsulab.connect.deeplink",
                "CFBundleURLSchemes": ["bjjossapp"]
            ]
        ],
        "KAKAO_NATIVE_APP_KEY": "$(KAKAO_NATIVE_APP_KEY)",
        "GoogleSignIn": "$(GOOGLE_SIGN_IN)",
        // 구글 로그인 client ID. URL 스킴과 같은 값에서 만든다 — dev Firebase plist에는 CLIENT_ID가 없다(#423).
        "GIDClientID": "$(GOOGLE_CLIENT_ID).apps.googleusercontent.com",
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
        // 도메인 변경 진입 버튼은 DEBUG/BETA 빌드에서만 노출되므로 Release에서는 `releaseInfoPlistScript`가 지운다(#353).
        "NSAppTransportSecurity": [
            "NSAllowsArbitraryLoadsInWebContent": true,
            "NSAllowsLocalNetworking": true,
        ],
        "LSApplicationQueriesSchemes": [
            "kakaokompassauth",
            "kakaolink"
        ],
        "FirebaseAppDelegateProxyEnabled": false,
        // 분석(#423): 화면 기록은 사전의 화면 이름으로 직접 남긴다(UIKit 클래스 이름이 섞이지 않게).
        // 광고 식별 · 광고 측정은 쓰지 않는다. 수집 켜기 · 끄기는 설정 "이용 통계"가 코드로 정한다.
        "FirebaseAutomaticScreenReportingEnabled": false,
        "GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE": false,
        "GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA": false,
        "GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS": false,
        "GOOGLE_ANALYTICS_REGISTRATION_WITH_AD_NETWORK_ENABLED": false,
        // 구성별 값은 앱 타깃 configurations. Crashlytics는 문자열 "YES"/"NO"도 읽는다.
        // setCrashlyticsCollectionEnabled는 쓰지 않는다 — UserDefaults에 남아 같은 번들 id로 깐 다른 구성에도 따라간다.
        "FirebaseCrashlyticsCollectionEnabled": "$(CRASHLYTICS_COLLECTION_ENABLED)",
        // 프로필 이미지 수정 + 커뮤니티 글 작성 웹뷰(<input type=file>) — 카메라 촬영
        "NSCameraUsageDescription": "프로필 사진, 글에 올릴 사진, 관장 사범 인증 서류를 찍을 때 카메라를 사용해요.",
        // 기능상 필수는 아님(PHPicker/웹뷰 파일 입력은 권한 프롬프트 없이 동작)이나
        // 보관함 접근 안내 일관성을 위해 명시.
        "NSPhotoLibraryUsageDescription": "프로필 사진과 글에 올릴 사진을 고를 때 사진 보관함에 접근해요.",
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
                // AppAssets: 앱 아이콘과 런치 화면 전용. 시스템이 앱 본체에서만 읽는다.
                "Targets/App/Resources/**",
                // GoogleService-Info.plist는 구성별로 firebaseConfigScript가 넣는다(#423).
                // UIAppFonts는 앱 본체에서 찾으므로 폰트 파일은 앱 타깃에만 넣는다(#224).
                .glob(pattern: .relativeToRoot("Targets/DesignSystem/Resources/Fonts/**"))
            ],
            scripts: [licensesScript, firebaseConfigScript, releaseInfoPlistScript, crashlyticsDSYMUploadScript],
            dependencies: [
                .target(name: "Presentation"),
                .target(name: "Data"),
                .target(name: "CoreKit"),
                .external(name: "Pulse"),
                .external(name: "PulseUI"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
                .external(name: "FirebaseCrashlytics"),
                // 광고 식별자(IDFA)를 쓰지 않는 Core만 넣는다. `FirebaseAnalytics` 제품은 넣지 않는다(#423).
                .external(name: "FirebaseAnalyticsCore"),
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
                        // 개발 중 크래시는 콘솔에 올리지 않는다
                        "CRASHLYTICS_COLLECTION_ENABLED": "NO",
                    ]),
                    .release(name: "Beta", settings: [
                        "OTHER_LDFLAGS": "$(inherited)",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition) BETA",
                        // Release와 별도 파일 — APNs는 production이지만 유니버설 링크는
                        // 이 구성이 로드하는 WEB_URL_DEV(dev 도메인)를 등록해야 한다.
                        "CODE_SIGN_ENTITLEMENTS": "JiuJitsuConnect.Beta.entitlements",
                        "CRASHLYTICS_COLLECTION_ENABLED": "YES",
                    ]),
                    .release(name: "Release", settings: [
                        "OTHER_LDFLAGS": "$(inherited)",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\(additionalCondition)",
                        "CODE_SIGN_ENTITLEMENTS": "JiuJitsuConnect.Release.entitlements",
                        "CRASHLYTICS_COLLECTION_ENABLED": "YES",
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
            // Fonts는 앱 타깃에만 넣는다(#224). 나머지는 이 프레임워크 번들에서 읽는다.
            resources: [
                "Targets/DesignSystem/Resources/Assets.xcassets",
                "Targets/DesignSystem/Resources/Colors.xcassets",
                "Targets/DesignSystem/Resources/Localizable.xcstrings",
                "Targets/DesignSystem/Resources/Lottie/**"
            ],
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
            // Xcode에서 실행할 때만 GA 기록을 DebugView에 바로 보낸다. 아카이브(TestFlight)에는 실행 인자가 들어가지 않는다
            runAction: .runAction(
                configuration: "Beta",
                arguments: .arguments(launchArguments: [.launchArgument(name: "-FIRDebugEnabled", isEnabled: true)])
            ),
            archiveAction: .archiveAction(configuration: "Beta")
        ),
        .scheme(
            name: "SwiftLint",
            shared: true,
            buildAction: .buildAction(targets: [.target("SwiftLint")])
        )
    ]
)
