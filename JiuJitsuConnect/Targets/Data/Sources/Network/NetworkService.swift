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
    private let tokenStorage: TokenStorage
    private let decoder: JSONDecoder
    
    public init(
        session: URLSession = .shared,
        tokenStorage: TokenStorage = DefaultTokenStorage(),
        decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
    ) {
        self.session = session
        self.tokenStorage = tokenStorage
//        #if DEBUG
//        self.session = URLSessionProxy(configuration: .default)
//        #else
//        self.session = URLSession(configuration: .default)
//        #endif
        
        self.decoder = decoder
    }
    
    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint: endpoint)
        
        do {
            let baseResponse = try self.decoder.decode(BaseResponseDTO<T>.self, from: data)
            
            if baseResponse.success, let responseData = baseResponse.data {
                return responseData
            } else {
                let apiError = APIErrorResponseDTO(
                    success: baseResponse.success,
                    code: baseResponse.code,
                    message: baseResponse.message
                )
                throw NetworkError.statusCodeError(statusCode: 200, response: apiError)
            }
        } catch let error as NetworkError {
            throw error // 위에서 던진 statusCodeError를 다시 던집니다.
        } catch {
            throw NetworkError.decodingError(error) // BaseResponseDTO 디코딩 자체에 실패한 경우
        }
    }
    
    public func requestVoid(endpoint: Endpoint) async throws {
        // requestData를 호출하여 응답을 확인하지만, 반환값은 사용하지 않습니다.
        // 에러가 발생하면 requestData 내부에서 throw 할 것입니다.
        _ = try await requestData(endpoint: endpoint)
    }
    
    public func requestData(endpoint: Endpoint) async throws -> Data {
        guard var urlRequest = endpoint.asURLRequest() else {
            throw NetworkError.invalidURL
        }

        if urlRequest.value(forHTTPHeaderField: "Authorization") == nil,
           let accessToken = tokenStorage.getAccessToken() {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        #if DEBUG
        NetworkLogger.log(request: urlRequest)
        #endif
        
        let data: Data
        let response: URLResponse
        
        // --- 1. API 요청 및 데이터 수신 (URLError 처리 포함) ---
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw NetworkError.noConnection
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.unknown(error)
            }
        } catch {
            throw NetworkError.unknown(error)
        }
        
        // --- 2. HTTP 응답 및 상태 코드 확인 ---
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        #if DEBUG
        NetworkLogger.log(response: httpResponse, data: data)
        #endif
        
        // --- 3. 상태 코드로 성공/실패 분기 ---
        guard (200...299).contains(httpResponse.statusCode) else {
            // 실패 시, 응답 데이터를 APIErrorResponseDTO로 디코딩 시도
            let apiError = try? self.decoder.decode(APIErrorResponseDTO.self, from: data)
            throw NetworkError.statusCodeError(statusCode: httpResponse.statusCode, response: apiError)
        }
        
        return data
    }
}
