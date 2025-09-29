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
    var bodyParameters: [String: Any]? { get } // POST body용
    var body: Data? { get }
    var timeout: TimeInterval { get } // 타임아웃 설정
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
    
    var bodyParameters: [String: Any]? {
        return nil
    }
    
    var timeout: TimeInterval {
        return 30.0
    }
    
    var body: Data? {
        guard let params = bodyParameters,
              let data = try? JSONSerialization.data(withJSONObject: params) else {
            return nil
        }
        return data
    }
    
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
