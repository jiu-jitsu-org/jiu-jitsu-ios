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
            return .toast("\(provider.displayName) 계정을 확인한 뒤 다시 시도해 주세요")
            
        case .permissionRequired(_, let permissionName):
            return .toast("서비스를 이용하려면 [\(permissionName)] 제공에 동의해 주세요")
            
        case .apiError(let code, _):
            // 이 매퍼는 "공통" 매퍼입니다.
            // API 에러는 각 Feature에서 문맥에 맞게 처리하는 것이 가장 좋습니다.
            // 여기서 반환하는 메시지는 Feature가 API 에러를 놓쳤을 때의 "폴백(fallback)"입니다.
            let message = code.displayMessage
            
            if message.isEmpty {
                // .nicknameDuplicated, .notMatchCategory 등
                // Feature에서 처리했어야 하는 에러가 여기까지 왔을 때
                Log.trace("Unhandled API Error: \(code.rawValue). This should be handled in the specific feature.", category: .network, level: .error)
                return .info(APIErrorCode.unknown.displayMessage)
            } else {
                // .authenticationFailed, .wrongParameter 등
                // displayMessage가 채워져 있는 공통 API 에러
                return .info(message)
            }
            
        case .serverError(let code, _, _):
            // 앱이 모르는 서버 코드는 예전처럼 알 수 없는 API 오류 문구로 둔다(#379 전에는 .apiError(.unknown)이었음).
            if code != nil {
                return .info(APIErrorCode.unknown.displayMessage)
            }
            return .toast("잠시 문제가 생겼어요. 다시 시도해 주세요")
        
        // 개발자 확인용 에러는 일반 메시지로 통일
        case .dataParsingFailed, .cannotFindRootViewController, .dependencyNotFound, .missingProfileData, .unknown:
            Log.trace("Critical Error: \(domainError)", category: .network, level: .error)
            return .toast("잠시 문제가 생겼어요. 다시 시도해 주세요")
        }
    }
}

// MARK: - 로그인 · 가입 · 탈퇴 실패 안내 (#379)

/// 로그인 · 가입 · 탈퇴가 실패했을 때 보여 줄 문구와, 문의 때 쓸 오류 코드.
/// 코드는 문구에 넣지 않는다 — 토스트는 몇 초 뒤 사라져 받아 적기 어렵고, 문의 메일의 '최근 오류'로 이미 전달된다.
public struct AuthFailureNotice: Equatable, Sendable {
    public let message: String
    /// 오류 코드(서버 코드나 HTTP 상태). 문의 메일의 '최근 오류'로 남긴다.
    public let code: String?
}

extension DomainErrorMapper {
    /// 모두 "알 수 없는 오류"로 뭉뚱그리면 사용자는 뭘 해야 할지, 문의를 받아도 어떤 오류인지 알 수 없다.
    /// 사용자가 알아야 할 이유(탈퇴 처리 · 영구 삭제)는 서버 문구로, 나머지는 다시 시도 안내로 알리고 코드는 따로 남긴다.
    /// 서버 문구는 개발용("서버에 문의해 주세요" 등)이 섞일 수 있어 아래 두 코드만 쓴다. 취소는 nil(안내 없음).
    public static func authFailure(from error: DomainError) -> AuthFailureNotice? {
        switch error {
        case .signInCancelled:
            return nil
        case let .apiError(code, message) where code == .alreadyWithdrawn || code == .withdrawnAccountExpired:
            let text = message.flatMap { $0.isEmpty ? nil : $0 }
            return AuthFailureNotice(message: text ?? Self.retryMessage, code: code.rawValue)
        case .apiError(.socialVerificationFailed, _):
            let code = APIErrorCode.socialVerificationFailed.rawValue
            return AuthFailureNotice(message: "로그인 정보를 확인하지 못했어요. 다시 시도해 주세요", code: code)
        case let .apiError(code, _):
            return AuthFailureNotice(message: Self.retryMessage, code: code.rawValue)
        case let .serverError(code, statusCode, _):
            // 서버 코드가 없으면 HTTP 상태라도 남긴다.
            let shown = code ?? statusCode.map(String.init)
            return AuthFailureNotice(message: Self.retryMessage, code: shown)
        case .networkUnavailable, .accountProblem, .permissionRequired,
             .dataParsingFailed, .cannotFindRootViewController, .dependencyNotFound, .missingProfileData, .unknown:
            switch toDisplayError(from: error) {
            case .toast(let message), .info(let message), .alert(let message):
                return AuthFailureNotice(message: message, code: nil)
            case .none:
                return nil
            }
        }
    }

    private static let retryMessage = "잠시 문제가 생겼어요. 다시 시도해 주세요"
}
