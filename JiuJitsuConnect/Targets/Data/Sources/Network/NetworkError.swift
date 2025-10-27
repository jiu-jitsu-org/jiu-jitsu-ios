//
//  NetworkError.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation
import Domain

// TODO: - ServerError 표준화
public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case statusCodeError(statusCode: Int, response: APIErrorResponseDTO?)
    case timeout
    case noConnection
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .decodingError:
            return "데이터를 변환하는 데 실패했습니다."
        case .statusCodeError(_, let response):
            return response?.message ?? "서버 오류가 발생했습니다."
        case .timeout:
            return "요청 시간이 초과되었습니다."
        case .noConnection:
            return "네트워크 연결을 확인해 주세요."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
    
    // TCA에서 활용하기 좋은 computed property 추가
    public var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection:
            return true
        case .statusCodeError(let statusCode, _):
            return statusCode >= 500 // 5xx 에러는 재시도 가능
        default:
            return false
        }
    }
    
    public func toDomainError() -> DomainError {
        switch self {
        case .noConnection, .timeout:
            return .networkUnavailable
            
        case .decodingError:
            return .dataParsingFailed
            
        case .statusCodeError(_, let response):
            // 기존 AuthRepositoryImpl에 있던 로직을 그대로 가져옵니다.
            if let response, !response.code.isEmpty {
                // 서버에서 받은 code(String)를 APIErrorCode(enum)으로 변환
                let errorCode = APIErrorCode(rawValue: response.code) ?? .unknown
                return .apiError(code: errorCode, message: response.message)
            }
            // APIErrorResponseDTO가 없거나 코드가 비어있는 5xx, 4xx 에러
            return .serverError(message: response?.message)
            
        case .invalidURL, .invalidResponse, .unknown:
            // 개발자가 확인해야 하는 시스템 레벨 오류
            return .unknown("네트워크 시스템 오류: \(self.localizedDescription)")
        }
    }
}
