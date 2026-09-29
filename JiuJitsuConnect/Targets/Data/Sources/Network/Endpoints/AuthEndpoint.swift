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

    // 인증 엔드포인트는 스스로 토큰을 발급/갱신하므로 401 인터셉터의 재시도 대상에서 제외한다.
    var allowsAuthRetry: Bool { false }

    // 로그인/refresh는 토큰을 새로 받는 요청이라 기존(만료 가능) 토큰을 실으면 A0003으로 거부된다.
    // logout은 기존 동작(헤더 주입)을 유지한다.
    var requiresAuth: Bool {
        switch self {
        case .serverLogin, .refresh:
            return false
        case .serverLogout:
            return true
        }
    }
    
    var body: Data? {
        switch self {
        case .serverLogin(let request):
            return try? JSONEncoder().encode(request)
        case .serverLogout(let request):
            return try? JSONEncoder().encode(request)
        case .refresh(let request):
            return try? JSONEncoder().encode(request)
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
