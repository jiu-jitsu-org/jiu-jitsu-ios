//
//  CompetitionEndpoint.swift
//  Data
//

import Foundation

enum CompetitionEndpoint {
    /// 등록된 대회 검색 (GET `/api/competition?keyword=`)
    /// backend #165 미구현 — 경로·파라미터 이름은 다른 엔드포인트(`/api/notice` 목록 등) 규칙에 맞춘 가정이다.
    case search(keyword: String)
}

extension CompetitionEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .search: return "/api/competition"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search: return .get
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case let .search(keyword): return ["keyword": keyword]
        }
    }
}
