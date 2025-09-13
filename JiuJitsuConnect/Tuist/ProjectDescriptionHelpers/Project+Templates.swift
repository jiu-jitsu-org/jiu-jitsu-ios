import ProjectDescription

public protocol TargetBuildable {
    var name: String { get }
    var destinations: Destinations { get }
    var product: Product { get }
    var bundleId: String { get }
    var sources: SourceFilesList { get }
    var dependencies: [TargetDependency] { get }
}

public extension Target {
    static func make(buildable: TargetBuildable) -> Target {
        return .target(
            name: buildable.name,
            destinations: buildable.destinations,
            product: buildable.product,
            bundleId: buildable.bundleId,
            infoPlist: .default,
            sources: buildable.sources,
            resources: [], // 필요 시 ["Resources/**"] 와 같이 추가
            dependencies: buildable.dependencies
        )
    }
}
