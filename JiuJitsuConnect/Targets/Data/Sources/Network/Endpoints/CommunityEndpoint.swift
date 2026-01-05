//
//  CommunityEndpoint.swift
//  Data
//
//  Created by suni on 1/5/26.
//

import Foundation

enum CommunityEndpoint {
    case getProfile
    case postProfile(PostCommunityProfileRequestDTO)
}

extension CommunityEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
//        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "TEST_BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .getProfile, .postProfile:
            return "/api/community/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getProfile:
            return .get
        case .postProfile:
            return .post
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    var body: Data? {
        switch self {
        case .getProfile:
            return nil
        case .postProfile(let request):
            return try? JSONEncoder().encode(request)
        }
    }
}
