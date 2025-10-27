//
//  DomainError.swift
//  Domain
//
//  Created by suni on 10/2/25.
//

import Foundation

public enum DomainError: Error, Equatable {
    // MARK: - 인증(Auth) 관련 에러
    /// 사용자가 직접 로그인을 취소한 경우
    case signInCancelled
    /// 비활성/정지 등 SNS 계정 자체의 문제
    case accountProblem(provider: SNSProvider)
    /// 필수 정보 제공에 동의하지 않은 경우
    case permissionRequired(provider: SNSProvider, permissionName: String)
    /// SDK에서 프로필 정보를 가져오지 못한 경우
    case missingProfileData
    
    // MARK: - 네트워크(Network) 관련 에러
    /// 서버가 정의한 비즈니스 에러 (코드를 enum으로 관리)
    case apiError(code: APIErrorCode, message: String?)
    /// 인터넷 연결 문제 (네트워크 끊김, 타임아웃 등)
    case networkUnavailable
    /// 서버 비즈니스 에러 또는 5xx 에러
    case serverError(message: String?)
    
    // MARK: - 개발/환경(Development) 관련 에러
    /// 최상위 ViewController를 찾을 수 없음
    case cannotFindRootViewController
    /// 의존성 주입 실패
    case dependencyNotFound
    /// 데이터 파싱 실패
    case dataParsingFailed
    
    // MARK: - 기타
    case unknown(String?)
}
