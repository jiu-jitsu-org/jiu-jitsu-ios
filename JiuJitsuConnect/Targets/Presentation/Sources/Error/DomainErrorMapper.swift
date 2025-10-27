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
            
        case .apiError(let code, _):
            // 이 매퍼는 "공통" 매퍼입니다.
            // API 에러는 각 Feature에서 문맥에 맞게 처리하는 것이 가장 좋습니다.
            // 여기서 반환하는 메시지는 Feature가 API 에러를 놓쳤을 때의 "폴백(fallback)"입니다.
            let message = code.displayMessage
            
            if message.isEmpty {
                // .nicknameDuplicated, .notMatchCategory 등
                // Feature에서 처리했어야 하는 에러가 여기까지 왔을 때
                Logger.network.error("Unhandled API Error: \(code.rawValue). This should be handled in the specific feature.")
                return .info(APIErrorCode.unknown.displayMessage)
            } else {
                // .authenticationFailed, .wrongParameter 등
                // displayMessage가 채워져 있는 공통 API 에러
                return .info(message)
            }
            
        case .serverError:
            return .toast("오류가 발생했습니다. 잠시 후 다시 시도해주세요.")
        
        // 개발자 확인용 에러는 일반 메시지로 통일
        case .dataParsingFailed, .cannotFindRootViewController, .dependencyNotFound, .missingProfileData, .unknown:
            Logger.network.error("Critical Error: \(domainError)")
            return .toast("오류가 발생했습니다. 잠시 후 다시 시도해주세요.")
        }
    }
}
