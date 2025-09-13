import ProjectDescription
import ProjectDescriptionHelpers

struct AppTarget: TargetBuildable {
    let name = "JiuJitsuLabConnect"
    let destinations: Destinations = .iOS
    let product: Product = .app
    let bundleId = "com.jiujitsulab.connect"
    let sources: SourceFilesList = ["Targets/App/Sources/**"]
    let dependencies: [TargetDependency] = [.target(name: "Presentation")]
}

// UI와 상태 관리를 담당 (TCA)
struct PresentationTarget: TargetBuildable {
    let name = "Presentation"
    let destinations: Destinations = .iOS
    let product: Product = .framework
    let bundleId = "com.jiujitsulab.connect.presentation"
    let sources: SourceFilesList = ["Targets/Presentation/Sources/**"]
    let dependencies: [TargetDependency] = [
        .target(name: "Domain"),
        .external(name: "ComposableArchitecture")
    ]
}

// 핵심 비즈니스 로직 담당
struct DomainTarget: TargetBuildable {
    let name = "Domain"
    let destinations: Destinations = .iOS
    let product: Product = .framework
    let bundleId = "com.jiujitsulab.connect.domain"
    let sources: SourceFilesList = ["Targets/Domain/Sources/**"]
    let dependencies: [TargetDependency] = [
        .target(name: "Data")
    ]
}

// 네트워킹, DB 등 데이터 소스 담당
struct DataTarget: TargetBuildable {
    let name = "Data"
    let destinations: Destinations = .iOS
    let product: Product = .framework
    let bundleId = "com.jiujitsulab.connect.data"
    let sources: SourceFilesList = ["Targets/Data/Sources/**"]
    let dependencies: [TargetDependency] = []
}

let project = Project(
    name: "JiuJitsuConnect",
    organizationName: "com.jiujitsulab",
    targets: [
        .make(buildable: AppTarget()),
        .make(buildable: PresentationTarget()),
        .make(buildable: DomainTarget()),
        .make(buildable: DataTarget())
    ]
)
