//
//  AuthEndpoint.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation
import Domain

enum AuthEndpoint {
    case serverLogin(LoginRequestDTO)
    case serverLogout(LogoutRequestDTO)
    case refresh(RefreshRequestDTO)
}

extension AuthEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
//        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "TEST_BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .serverLogin:
            return "/api/auth/sns-login"
        case .serverLogout:
            return "/api/auth/logout"
        case .refresh:
            return "/api/auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .serverLogin, .serverLogout, .refresh:
            return .post
        }
    }
    
    // TODO: refresh 엔드포인트를 다시 body로 변경해야 함 (임시로 query parameter 사용 중)
    var queryParameters: [String: String]? {
        switch self {
        case .refresh(let request):
            return ["refreshToken": request.refreshToken]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .serverLogin(let request):
            return try? JSONEncoder().encode(request)
        case .serverLogout(let request):
            return try? JSONEncoder().encode(request)
        case .refresh:
            // TODO: 임시로 query parameter 사용 중 - 나중에 body로 다시 변경 필요
            return nil
        }
    }
}

private extension Encodable {
    // Encodable을 [String: Any]?로 변환하는 헬퍼
    var toDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    }
}
