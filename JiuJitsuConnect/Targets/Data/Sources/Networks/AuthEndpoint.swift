//
//  AuthEndpoint.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation
import Domain

enum AuthEndpoint {
    case appLogin(AuthRequest)
}

extension AuthEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .appLogin:
            return "/api/auth/sns-login"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .appLogin:
            return .post
        }
    }
    
    // POST 요청의 body를 설정
    var parameters: [String: Any]? {
        switch self {
        case .appLogin(let request):
            return request.toDictionary
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
