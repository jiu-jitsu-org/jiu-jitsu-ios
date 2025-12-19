//
//  UserEndpoint.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation
import Domain

enum UserEndpoint {
    case signup(request: SignupRequestDTO, tempToken: String)
    case checkNickname(request: CheckNicknameRequestDTO)
    case withdrawal
}

extension UserEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "TEST_BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .signup, .withdrawal:
            return "/api/user"
        case .checkNickname:
            return "/api/user/check/nickname"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .checkNickname:
            return .get
        case .signup:
            return .post
        case .withdrawal:
            return .delete
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .signup(_, let tempToken):
            return ["Content-Type": "application/json", "Authorization": "Bearer \(tempToken)"]
        default:
            return ["Content-Type": "application/json"]
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .checkNickname(let request):
            return ["nickname": request.nickname]
        default: return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .signup(let request, _):
            return try? JSONEncoder().encode(request)
        default: return nil
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
