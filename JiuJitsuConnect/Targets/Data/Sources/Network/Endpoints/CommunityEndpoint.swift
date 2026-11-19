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
    case getPublicProfile(userId: Int)
    /// 신고 (`POST /api/reports`) — 회원 신고(#328)
    case postReport(PostReportRequestDTO)
    /// 회원 차단 (`POST /api/user/block/{id}`) — 응답은 차단 상태(Bool)
    case blockUser(userId: Int)
    /// 회원 차단 해제 (`DELETE /api/user/block/{id}`)
    case unblockUser(userId: Int)
}

extension CommunityEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .getProfile, .postProfile:
            return "/api/community/profile"
        case let .getPublicProfile(userId):
            return "/api/community/profile/\(userId)"
        case .postReport:
            return "/api/reports"
        case let .blockUser(userId), let .unblockUser(userId):
            return "/api/user/block/\(userId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getProfile, .getPublicProfile:
            return .get
        case .postProfile, .postReport, .blockUser:
            return .post
        case .unblockUser:
            return .delete
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
        case .getProfile, .getPublicProfile, .blockUser, .unblockUser:
            return nil
        case .postProfile(let request):
            return try? JSONEncoder().encode(request)
        case .postReport(let request):
            return try? JSONEncoder().encode(request)
        }
    }
}
