//
//  AuthRepositoryImpl.swift
//  JiuJitsuConnect
//
//  Created by suni on 9/21/25.
//

import Foundation
import Domain
import GoogleSignIn
import AuthenticationServices
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

public final class AuthRepositoryImpl: NSObject, AuthRepository, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let networkService: NetworkService
    
    private var appleSignInContinuation: CheckedContinuation<SNSUser, Error>?
    
    public init(networkService: NetworkService  = DefaultNetworkService(), appleSignInContinuation: CheckedContinuation<SNSUser, Error>? = nil) {
        self.networkService = networkService
        self.appleSignInContinuation = appleSignInContinuation
    }
    
    @MainActor
    public func signInWithGoogle() async throws -> Domain.SNSUser {
        do {
            let rootViewController = try findRootViewController()
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            return try mapToSnsUser(from: result.user)
        } catch let error as GIDSignInError {
            throw mapToAuthError(from: error, provider: .google)
        }
    }
    
    @MainActor
    public func signInWithApple() async throws -> Domain.SNSUser {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = []
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    @MainActor
    public func signInWithKakao() async throws -> Domain.SNSUser {
        return try await withCheckedThrowingContinuation { continuation in
            
            // 카카오톡 앱으로 로그인 시도
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                    guard let self else { return }
                    if let error = error {
                        let authError = mapToAuthError(from: error, provider: .kakao)
                        continuation.resume(throwing: authError)
                    } else if let oauthToken = oauthToken {
                        let snsUser = Domain.SNSUser(
                            idToken: oauthToken.accessToken,
                            snsProvider: .kakao
                        )
                        continuation.resume(returning: snsUser)
                    } else {
                        let authError = mapToAuthError(from: AuthError.unknown("Kakao login failed with no token and no error."), provider: .kakao)
                        continuation.resume(throwing: authError)
                    }
                }
            } else {
                // 카카오 계정(웹뷰)으로 로그인 시도
                UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                    guard let self else { return }
                    if let error = error {
                        let authError = mapToAuthError(from: error, provider: .kakao)
                        continuation.resume(throwing: authError)
                    } else if let oauthToken = oauthToken {
                        let snsUser = Domain.SNSUser(
                            idToken: oauthToken.accessToken,
                            snsProvider: .kakao
                        )
                        continuation.resume(returning: snsUser)
                    } else {
                        let authError = mapToAuthError(from: AuthError.unknown("Kakao login failed with no token and no error."), provider: .kakao)
                        continuation.resume(throwing: authError)
                    }
                }
            }
        }
    }
    
    public func appLogin(request: AuthRequest) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.appLogin(request)
        return try await networkService.request(endpoint: endpoint)
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                appleSignInContinuation?.resume(throwing: AuthError.missingProfileData)
                return
            }
            
            let user = SNSUser(
                idToken: tokenString,
                snsProvider: .apple
            )
            appleSignInContinuation?.resume(returning: user)
        } else {
            appleSignInContinuation?.resume(throwing: AuthError.unknown("Apple credential is not AppleIDCredential."))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = mapToAuthError(from: error, provider: .apple)
        appleSignInContinuation?.resume(throwing: authError)
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // findRootViewController()를 통해 현재 활성화된 window를 반환합니다.
        // 이 메서드는 MainActor에서 호출되므로 try! 사용이 비교적 안전합니다.
        return try! findRootViewController().view.window!
    }
    
    public func signOut() async throws {
        await MainActor.run {
            GIDSignIn.sharedInstance.signOut()
            
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func findRootViewController() throws -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            throw AuthError.cannotFindRootViewController
        }
        return rootViewController
    }
    
    private func mapToSnsUser(from gidUser: GIDGoogleUser) throws -> Domain.SNSUser {
        guard let idToken = gidUser.idToken?.tokenString else {
            throw AuthError.missingProfileData
        }
        return Domain.SNSUser(
            idToken: idToken,
            snsProvider: .google
        )
    }
    
    // MARK: - Error Mapping
    
    private func mapToAuthError(from error: Error, provider: SNSProvider) -> AuthError {
        // 원본 에러는 여기서 분석을 위해 로깅하는 것이 좋습니다.
        // Logger.error("Original Auth Error from \(provider.rawValue): \(error)")
        
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
                // 말 그대로 원인을 알 수 없는 오류.
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
                // 향후 Apple이 새로운 에러 코드를 추가하더라도 앱이 크래시되지 않도록 처리
                return .unknown(asError.localizedDescription)
            }
        }
        
        // --- Kakao 에러 매핑 ---
        if let sdkError = error as? KakaoSDKCommon.SdkError {
            
            // 1. 클라이언트 에러 (네트워크 외적인 문제)
            if sdkError.isClientFailed {
                let clientError = sdkError.getClientError()
                switch clientError.reason {
                case .Cancelled:
                    // 사용자가 직접 취소 (웹뷰 닫기, 카톡 앱에서 돌아오기 등)
                    return .signInCancelled
                    
                case .TokenNotFound:
                    // SDK 내부에 토큰이 없는 경우. 계정 문제로 간주.
                    return .accountProblem(provider: .kakao)
                    
                case .NotSupported:
                    // 카카오톡이 설치되지 않은 상태에서 talk 로그인 시도 등
                    // 이 경우는 Repository에서 이미 분기 처리 했으므로 발생 가능성 낮음.
                    return .unknown("카카오톡이 설치되어 있지 않습니다.")
                    
                default:
                    // 그 외 클라이언트 에러는 일반 오류로 처리
                    return .unknown(clientError.message)
                }
            }
            
            // 2. 인증/인가 에러 (로그인 자체의 문제)
            if sdkError.isAuthFailed {
                let authError = sdkError.getAuthError()
                switch authError.reason {
                case .AccessDenied:
                    // 사용자가 동의 화면에서 필수 항목을 거부했거나 '취소'를 누름
                    return .permissionRequired(provider: .kakao, permissionName: "필수 동의 항목")
                    
                case .InvalidGrant, .InvalidClient:
                    // 리프레시 토큰 만료, 잘못된 앱 키 등. 계정 문제로 간주.
                    return .accountProblem(provider: .kakao)
                    
                default:
                    return .unknown(authError.info?.errorDescription)
                }
            }
            
            // 3. API 에러 (로그인 성공 후, 'me()' 호출 등에서 발생)
            if sdkError.isApiFailed {
                let apiError = sdkError.getApiError()
                switch apiError.reason {
                case .InsufficientScope:
                    // 필요한 동의 항목(ex. 이메일)을 사용자가 동의하지 않음
                    let requiredScopes = apiError.info?.requiredScopes?.joined(separator: ", ") ?? "필수 항목"
                    return .permissionRequired(provider: .kakao, permissionName: requiredScopes)
                    
                case .NotSignedUpUser, .NotKakaoAccountUser, .Blocked:
                    // 가입되지 않았거나, 휴면/제재 계정. 계정 문제로 간주.
                    return .accountProblem(provider: .kakao)
                    
                case .InvalidAccessToken:
                    // 토큰이 만료되었거나 유효하지 않음. 다시 로그인 필요.
                    return .accountProblem(provider: .kakao)
                    
                default:
                    return .unknown(apiError.info?.msg)
                }
            }
        }
        
        // 매핑되지 않은 모든 에러
        return .unknown(error.localizedDescription)
    }
}
