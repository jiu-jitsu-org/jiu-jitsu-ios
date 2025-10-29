//
//  APIErrorCode.swift
//  Domain
//
//  Created by suni on 10/27/25.
//

import Foundation

public enum APIErrorCode: String, Equatable {
    // MARK: - Auth (A0000)
    case authenticationFailed = "A0010" // 인증 실패
    case notMatchCategory = "A0002" // 잘못된 유형의 토큰
    case invalidRefreshToken = "A0009" // 유효하지 않은 refresh token
    
    // MARK: - Request (R0000)
    case wrongParameter = "R0002" // 잘못된 요청 데이터
    case nicknameDuplicated = "R0003" // 이미 사용중인 닉네임
        
    /// 클라이언트에서 알 수 없는 새로운 에러 코드를 처리하기 위한 케이스
    case unknown
    
    /// 사용자에게 보여줄 기본 에러 메시지
    public var displayMessage: String {
        switch self {
        default:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
