// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "JiuJitsuConnect",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.22.2"
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            branch: "main"
        ),
        .package(
            url: "https://github.com/onevcat/Kingfisher",
            branch: "master"
        ),
        .package(
            url: "https://github.com/kakao/kakao-ios-sdk",
            branch: "master"
        ),
        .package(
            url: "https://github.com/kean/Pulse",
            branch: "main"
        )
    ]
)
