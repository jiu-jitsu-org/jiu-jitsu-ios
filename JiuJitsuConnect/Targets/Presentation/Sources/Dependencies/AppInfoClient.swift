//import Foundation
//import ComposableArchitecture
//
//public struct AppInfoClient {
//    public var isUpdateNeeded: () async throws -> Bool
//}
//
//extension AppInfoClient: DependencyKey {
//    public static var liveValue: Self {
//        return Self(
//            isUpdateNeeded: {
//                // TODO: Domain 계층의 'VersionCheckUseCase'를 호출
//                guard let currentVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
//                    throw URLError(.badURL) // 적절한 에러 타입으로 변경 필요
//                }
//                
//                // API 통신을 통해 서버가 요구하는 최소 버전 가져오기 (임시 하드코딩)
//                let requiredVersionString = "1.1.0"
//                
//                return currentVersionString.compare(requiredVersionString, options: .numeric) == .orderedAscending
//            }
//        )
//    }
//    
//    // 테스트용 구현 (항상 업데이트 불필요)
//    public static var testValue: Self {
//        return Self(isUpdateNeeded: { false })
//    }
//    
//    // SwiftUI 프리뷰용 구현
//    public static var previewValue: Self {
//        return Self(isUpdateNeeded: { false })
//    }
//}
//
//public extension DependencyValues {
//    var appInfoClient: AppInfoClient {
//        get { self[AppInfoClient.self] }
//        set { self[AppInfoClient.self] = newValue }
//    }
//}
