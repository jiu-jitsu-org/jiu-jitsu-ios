//
//  AuthErrorMapper.swift
//  Data
//
//  Created by suni on 12/6/25.
//

import Foundation
import Domain
import GoogleSignIn
import AuthenticationServices
import KakaoSDKCommon
import CoreKit // Log 사용을 위해

struct AuthErrorMapper {
    
    static func map(from error: Error, provider: SNSProvider) -> DomainError {
        Log.trace("Original Auth Error from \(provider.rawValue): \(error)", category: .network, level: .error)
        
        // --- Google 에러 매핑 ---
        if let gidError = error as? GIDSignInError {
            switch gidError.code {
            case .canceled:
                return .signInCancelled
            case .keychain, .EMM:
                return .accountProblem(provider: .google)
            case .mismatchWithCurrentUser:
                return .missingProfileData
            default:
                return .unknown(gidError.localizedDescription)
            }
        }
        
        // --- Apple 에러 매핑 ---
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                // 사용자가 직접 인증 창을 닫은 경우
                return .signInCancelled
            case .invalidResponse, .notHandled, .failed:
                // Apple 서버의 응답이 잘못되었거나, 앱이 응답을 처리할 수 없거나,
                // 인증 자체가 실패한 경우. 대부분 일시적인 문제이거나 계정 문제일 수 있음.
                return .accountProblem(provider: .apple)
            case .unknown:
                // 사용자에게는 일반적인 실패로 안내하고, 개발자는 원본 에러를 로깅하여 원인 파악 필요.
                return .unknown(asError.localizedDescription)
            case .notInteractive:
                // 사용자의 추가적인 입력이 필요한데, 비대화형(non-interactive)으로 요청된 경우.
                // 이는 개발자의 코드 로직 오류일 가능성이 높음.
                return .unknown("Non-interactive authorization request failed.")
                // --- iOS 17.4+ Passkey 관련 에러 ---
                // (Passkey를 사용하지 않는다면 발생 가능성 낮음)
            case .matchedExcludedCredential, .credentialImport, .credentialExport:
                return .unknown("Passkey credential error.")
                // --- iOS 18+ 관련 에러 ---
                // (향후 OS 버전에 따라 추가될 수 있는 에러 처리)
            case .preferSignInWithApple:
                // 사용자가 다른 로그인 방식 대신 Apple 로그인을 선호하도록 시스템이 제안한 경우.
                // 실제 에러는 아니지만, 개발자가 이 시그널을 처리할 수 있음.
                return .unknown("User prefers Sign in with Apple.")
            case .deviceNotConfiguredForPasskeyCreation:
                // Passkey 생성을 위해 기기 설정이 필요함을 의미.
                return .accountProblem(provider: .apple)
            @unknown default:
                return .unknown(asError.localizedDescription)
            }
        }
        
        // --- Kakao 에러 매핑 ---
        if let sdkError = error as? KakaoSDKCommon.SdkError {
            if sdkError.isClientFailed, sdkError.getClientError().reason == .Cancelled {
                return .signInCancelled
            }
            if sdkError.isAuthFailed, sdkError.getAuthError().reason == .AccessDenied {
                return .permissionRequired(provider: .kakao, permissionName: "필수 동의 항목")
            }
            if sdkError.isAuthFailed || sdkError.isApiFailed {
                return .accountProblem(provider: .kakao)
            }
        }
        
        // 매핑되지 않은 모든 에러
        return .unknown(error.localizedDescription)
    }
}
