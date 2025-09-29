//
//  AuthError.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public enum AuthError: Error, LocalizedError, Equatable {
    // 1. 사용자 선택
    /// 사용자가 직접 로그인을 취소한 경우
    case signInCancelled
    
    // 2. 계정 문제
    /// 비활성/정지 등 SNS 계정 자체의 문제 (서버 검증 후 반환될 수도 있음)
    case accountProblem(provider: SNSProvider)
    
    // 3. 권한 문제
    /// 필수 정보 제공에 동의하지 않은 경우
    case permissionRequired(provider: SNSProvider, permissionName: String)
    
    // 4. 개발자/환경 문제 (사용자에게는 일반적인 실패로 안내)
    /// 최상위 ViewController를 찾지 못함
    case cannotFindRootViewController
    /// 프로필 정보가 누락됨 (SDK -> 앱)
    case missingProfileData
    /// DI 컨테이너 등 의존성 주입 실패
    case dependencyNotFound
    
    // 5. 기타 문제
    /// 그 외 모든 알 수 없는 오류
    case unknown(String?)

    // 사용자에게 보여줄 메시지 (에러 정책)
    public var errorDescription: String? {
        switch self {
        case .signInCancelled:
            return nil // 정책: 메시지 없음
        case .accountProblem(let provider):
            return "\(provider.displayName) 계정을 확인 후 다시 시도해주세요."
        case .permissionRequired(_, let permissionName):
            return "서비스 이용을 위해 [\(permissionName)] 제공 동의가 필요합니다."
        case .cannotFindRootViewController, .missingProfileData, .dependencyNotFound, .unknown:
            // 개발자 오류는 사용자에게 일반적인 메시지로 통일
            return "오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        }
    }
}
