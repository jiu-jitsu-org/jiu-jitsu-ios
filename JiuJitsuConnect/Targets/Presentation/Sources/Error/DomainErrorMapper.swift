//
//  DomainErrorMapper.swift
//  Presentation
//
//  Created by suni on 10/2/25.
//

import Foundation
import Domain
import OSLog
import CoreKit

public struct DomainErrorMapper {
    public static func toDisplayError(from domainError: DomainError) -> DisplayError {
        switch domainError {
        case .signInCancelled:
            return .none // 정책: UI 표시 안 함
        
        case .networkUnavailable:
            return .toast("네트워크 연결을 확인해주세요.")
            
        case .accountProblem(let provider):
            return .toast("\(provider.displayName) 계정을 확인 후 다시 시도해주세요.")
            
        case .permissionRequired(_, let permissionName):
            return .toast("서비스 이용을 위해 [\(permissionName)] 제공 동의가 필요합니다.")
            
        case .serverError:
            return .toast("오류가 발생했습니다. 잠시 후 다시 시도해주세요.")
        
        // 개발자 확인용 에러는 일반 메시지로 통일
        case .dataParsingFailed, .cannotFindRootViewController, .dependencyNotFound, .missingProfileData, .unknown:
            Logger.network.error("Critical Error: \(domainError)")
            return .toast("오류가 발생했습니다. 잠시 후 다시 시도해주세요.")
        }
    }
}
