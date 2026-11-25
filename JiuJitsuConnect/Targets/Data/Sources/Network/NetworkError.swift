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
    /// 401 후 토큰 갱신까지 실패(refresh 토큰 만료 등) — 재로그인이 필요한 세션 만료.
    case sessionExpired
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "요청 주소가 올바르지 않아요"
        case .invalidResponse:
            return "서버 응답이 올바르지 않아요"
        case .decodingError:
            return "받은 데이터를 읽지 못했어요"
        case .statusCodeError(_, let response):
            return response?.message ?? "서버에 문제가 생겼어요"
        case .timeout:
            return "서버 응답이 늦어요"
        case .noConnection:
            return "연결이 불안정해요"
        case .sessionExpired:
            return "로그인이 만료됐어요. 다시 로그인해 주세요"
        case .unknown:
            return "잠시 문제가 생겼어요"
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
        case .noConnection:
            return .networkUnavailable

        case .timeout:
            return .timeout
            
        case .decodingError:
            return .dataParsingFailed

        case .sessionExpired:
            // 세션 만료는 전역 로그아웃(AuthSessionEvent.sessionExpired)으로 별도 처리되며,
            // 호출부 에러 매핑에서는 refresh 토큰 무효와 동일하게 취급한다.
            return .apiError(code: .invalidRefreshToken, message: nil)

        case let .statusCodeError(statusCode, response):
            if let response, !response.code.isEmpty {
                if let errorCode = APIErrorCode(rawValue: response.code) {
                    return .apiError(code: errorCode, message: response.message)
                }
                // 앱이 모르는 코드는 원래 문자열을 그대로 남긴다 — 사용자 안내 · 문의에서 어떤 오류인지 알 수 있게(#379).
                return .serverError(code: response.code, statusCode: statusCode, message: response.message)
            }
            // APIErrorResponseDTO가 없거나 코드가 비어있는 5xx, 4xx 에러
            return .serverError(code: nil, statusCode: statusCode, message: response?.message)
            
        case .invalidURL, .invalidResponse, .unknown:
            // 개발자가 확인해야 하는 시스템 레벨 오류
            return .unknown("네트워크 시스템 오류: \(self.localizedDescription)")
        }
    }
}
