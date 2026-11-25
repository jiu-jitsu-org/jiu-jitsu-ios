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
    /// 서버에 닿지 못함 (연결 없음 · 연결 끊김 · 서버 연결 실패 등)
    case networkUnavailable
    /// 서버가 제때 답하지 않음. 연결 문제와 안내를 나눈다(#396).
    case timeout
    /// 앱이 모르는 서버 코드 또는 코드 없는 4xx · 5xx.
    /// 사용자 안내 · 문의에 쓰도록 원래 코드 문자열과 HTTP 상태를 남긴다(#379).
    case serverError(code: String?, statusCode: Int?, message: String?)
    
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
