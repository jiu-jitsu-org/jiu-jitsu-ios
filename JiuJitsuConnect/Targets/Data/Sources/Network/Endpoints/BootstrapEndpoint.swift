//
//  BootstrapEndpoint.swift
//  Data
//

import Foundation

enum BootstrapEndpoint {
    /// 앱 시작 정보 (GET `/api/bootstrap/info?osName=`). 로그인 없이 부른다. `osName` 기본값이 ANDROID라 꼭 보낸다.
    case getInfo(osName: String)
}

extension BootstrapEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .getInfo: return "/api/bootstrap/info"
        }
    }

    var method: HTTPMethod { .get }

    var queryParameters: [String: String]? {
        switch self {
        case let .getInfo(osName): return ["osName": osName]
        }
    }

    // 스플래시에서 자동 로그인과 함께 부른다. 만료된 토큰이 실려 거부되거나, 토큰 갱신을 기다리지 않게 토큰 없이 보낸다.
    var requiresAuth: Bool { false }

    var allowsAuthRetry: Bool { false }
}
