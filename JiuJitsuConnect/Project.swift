import ProjectDescription

// MARK: - Project
let project = Project(
    name: "JiuJitsuConnect",
    targets: [
        // MARK: - App Target (Executable)
        .target(
            name: "App",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.jiujitsulab.connect",
            sources: ["Targets/App/Sources/**"],
            resources: ["Targets/App/Resources/**"],
            dependencies: [
                .target(name: "Presentation")
            ]
        ),
        
        // MARK: - Presentation Target (UI & State Management)
        .target(
            name: "Presentation",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.jiujitsulab.connect.presentation",
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
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.jiujitsulab.connect.domain",
            sources: ["Targets/Domain/Sources/**"],
            dependencies: [
                .target(name: "CoreKit")
            ]
        ),
        
        // MARK: - Data Target (Data Handling)
        .target(
            name: "Data",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.jiujitsulab.connect.data",
            sources: ["Targets/Data/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "CoreKit")
            ]
        ),
        
        // MARK: - CoreKit Target (Shared Non-UI Modules)
        .target(
            name: "CoreKit",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.jiujitsulab.connect.corekit",
            sources: ["Targets/CoreKit/Sources/**"],
            dependencies: []
        ),
        
        // MARK: - DesignSystem Target (Shared UI Modules)
        .target(
            name: "DesignSystem",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.jiujitsulab.connect.designsystem",
            sources: ["Targets/DesignSystem/Sources/**"],
            resources: ["Targets/DesignSystem/Resources/**"],
            dependencies: [
                .target(name: "CoreKit")
            ]
        )
    ]
)
