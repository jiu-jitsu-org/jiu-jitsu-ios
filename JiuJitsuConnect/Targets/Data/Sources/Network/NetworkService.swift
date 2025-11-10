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
//        #if DEBUG
//        self.session = URLSessionProxy(configuration: .default)
//        #else
//        self.session = URLSession(configuration: .default)
//        #endif
        
        self.decoder = decoder
    }
    
    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        // 1. requestData를 통해 서버로부터 원본 데이터를 받아옵니다.
        //    (내부적으로 statusCode, network connection 등의 에러 처리가 모두 완료된 상태)
        let data = try await requestData(endpoint: endpoint)
        
        // 2. 전체 응답을 BaseResponseDTO로 디코딩합니다.
        do {
            let baseResponse = try self.decoder.decode(BaseResponseDTO<T>.self, from: data)
            
            // 3. API 응답이 성공이고, data가 존재하면 data만 반환합니다.
            if baseResponse.success, let responseData = baseResponse.data {
                return responseData
            } else {
            // 4. API가 정의한 비즈니스 에러일 경우, statusCodeError를 던집니다.
                let apiError = APIErrorResponseDTO(
                    success: baseResponse.success,
                    code: baseResponse.code,
                    message: baseResponse.message
                )
                // 성공 응답(2xx) 코드 내에서 발생하는 비즈니스 에러이므로, status code는 임의로 200으로 설정하거나
                // 혹은 별도의 DomainError로 처리할 수 있습니다. 여기서는 APIErrorResponseDTO를 담아 던집니다.
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
        guard let urlRequest = endpoint.asURLRequest() else {
            throw NetworkError.invalidURL
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
