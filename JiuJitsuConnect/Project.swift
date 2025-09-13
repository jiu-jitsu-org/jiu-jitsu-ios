import ProjectDescription

let project = Project(
    name: "JiuJitsuConnect",
    targets: [
        .target(
            name: "JiuJitsuConnect",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.JiuJitsuConnect",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["JiuJitsuConnect/Sources/**"],
            resources: ["JiuJitsuConnect/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "JiuJitsuConnectTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.JiuJitsuConnectTests",
            infoPlist: .default,
            sources: ["JiuJitsuConnect/Tests/**"],
            resources: [],
            dependencies: [.target(name: "JiuJitsuConnect")]
        ),
    ]
)
