//
//  AuthError.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public enum AuthError: Error, LocalizedError {
    case cannotFindRootViewController
    case missingProfileData
    case dependencyNotFound
    case signInCancelled
    
    public var errorDescription: String? {
        switch self {
        case .cannotFindRootViewController:
            return "루트 뷰 컨트롤러를 찾을 수 없습니다."
        case .missingProfileData:
            return "프로필 정보가 누락되었습니다."
        case .dependencyNotFound:
            return "의존성을 찾을 수 없습니다."
        case .signInCancelled:
            return "로그인이 취소되었습니다."
        }
    }
}
