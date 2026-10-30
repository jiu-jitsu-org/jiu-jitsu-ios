//
//  CompetitionEndpoint.swift
//  Data
//

import Foundation

enum CompetitionEndpoint {
    /// 등록된 대회 검색 (GET `/api/community/competitions?keyword=`)
    /// 서버가 공백·대소문자를 무시해 부분 일치로 찾고, 정렬해서 최대 20개를 준다.
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
        case .search: return "/api/community/competitions"
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
