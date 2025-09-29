//
//  NetworkError.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation

// TODO: - ServerError 표준화
public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data? = nil)
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
        case .serverError(let statusCode, _):
            return "서버 오류가 발생했습니다. (코드: \(statusCode))"
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
        case .serverError(let statusCode, _):
            return statusCode >= 500 // 5xx 에러는 재시도 가능
        default:
            return false
        }
    }
}
