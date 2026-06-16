//
//  Endpoint.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation

public protocol Endpoint: Sendable {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get } // GET 파라미터용
    var body: Data? { get }
    var timeout: TimeInterval { get } // 타임아웃 설정
    /// 401 수신 시 토큰 자동 갱신 후 재시도를 허용할지 여부.
    /// 토큰 생명주기를 직접 다루는 인증 엔드포인트(login/refresh/logout)는 false로 둬
    /// 인터셉터 재귀·로그인 도중 잘못된 세션 만료 통지를 막는다.
    var allowsAuthRetry: Bool { get }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public extension Endpoint {
    
    // 기본값 설정
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var queryParameters: [String: String]? {
        return nil
    }
    
    var timeout: TimeInterval {
        return 30.0
    }

    var allowsAuthRetry: Bool { true }

    var body: Data? { nil }
    
    func asURLRequest() -> URLRequest? {
        guard var urlComponents = URLComponents(string: baseURL) else { return nil }
        urlComponents.path += path
        
        // Query parameters 추가
        if let queryParams = queryParameters, !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { 
                URLQueryItem(name: $0.key, value: $0.value) 
            }
        }
        
        guard let url = urlComponents.url else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = timeout
        
        headers?.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        urlRequest.httpBody = body
        
        return urlRequest
    }
}
