//
//  NetworkService.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation

public protocol NetworkService: Sendable {
    func request<T: Decodable>(endpoint: Endpoint) async throws -> T
    
    // 빈 응답을 처리하는 경우 (DELETE, PUT 등)
    func requestVoid(endpoint: Endpoint) async throws
    
    // Raw Data가 필요한 경우 (파일 다운로드 등)
    func requestData(endpoint: Endpoint) async throws -> Data
}

public final class DefaultNetworkService: NetworkService {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
    ) {
        self.session = session
        self.decoder = decoder
    }
    
    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint: endpoint)
        
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    public func requestVoid(endpoint: Endpoint) async throws {
        _ = try await requestData(endpoint: endpoint)
    }
    
    public func requestData(endpoint: Endpoint) async throws -> Data {
        guard let urlRequest = endpoint.asURLRequest() else {
            throw NetworkError.invalidURL
        }
        
        #if DEBUG
        NetworkLogger.log(request: urlRequest)
        #endif
            
        // --- 1. API 요청 및 데이터 수신 ---
        let (data, response) = try await session.data(for: urlRequest)
        
        // --- 2. 응답 코드 확인 ---
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        #if DEBUG
        NetworkLogger.log(response: httpResponse, data: data)
        #endif
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // 실패 시, 응답 데이터를 APIErrorResponse로 디코딩 시도
            let apiError = try? decoder.decode(APIErrorResponseDTO.self, from: data)
            
            // 상태 코드와 디코딩된 에러를 함께 담아 throw
            throw NetworkError.statusCodeError(statusCode: httpResponse.statusCode, response: apiError)
        }
        
        return data
    }
}
