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
import OSLog
import CoreKit

public final class AuthRepositoryImpl: NSObject, AuthRepository, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let networkService: NetworkService

    private var appleSignInContinuation: CheckedContinuation<SNSUser, Error>?
    
    public init(networkService: NetworkService  = DefaultNetworkService(), appleSignInContinuation: CheckedContinuation<SNSUser, Error>? = nil) {
        self.networkService = networkService
        self.appleSignInContinuation = appleSignInContinuation
    }
    
    // MARK: - SNS Login
    
    @MainActor
    public func signInWithGoogle() async throws -> Domain.SNSUser {
        do {
            let rootViewController = try findRootViewController()
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            return try mapToSnsUser(from: result.user)
        } catch let error as GIDSignInError {
            throw mapToDomainError(from: error, provider: .google)
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
                        let authError = mapToDomainError(from: error, provider: .kakao)
                        continuation.resume(throwing: authError)
                    } else if let oauthToken = oauthToken {
                        let snsUser = Domain.SNSUser(
                            accessToken: oauthToken.accessToken,
                            snsProvider: .kakao
                        )
                        continuation.resume(returning: snsUser)
                    } else {
                        let authError = mapToDomainError(from: DomainError.unknown("Kakao login failed with no token and no error."), provider: .kakao)
                        continuation.resume(throwing: authError)
                    }
                }
            } else {
                // 카카오 계정(웹뷰)으로 로그인 시도
                UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                    guard let self else { return }
                    if let error = error {
                        let authError = mapToDomainError(from: error, provider: .kakao)
                        continuation.resume(throwing: authError)
                    } else if let oauthToken = oauthToken {
                        let snsUser = Domain.SNSUser(
                            accessToken: oauthToken.accessToken,
                            snsProvider: .kakao
                        )
                        continuation.resume(returning: snsUser)
                    } else {
                        let authError = mapToDomainError(from: DomainError.unknown("Kakao login failed with no token and no error."), provider: .kakao)
                        continuation.resume(throwing: authError)
                    }
                }
            }
        }
    }
    
    // MARK: - API
    
    public func serverLogin(user: SNSUser) async throws -> AuthInfo {
        do {
            // 1. Domain 모델(SNSUser)을 Data 모델(AuthRequestDTO)로 변환
            let requestDTO = user.toRequestDTO()
            
            // 2. 변환된 DTO를 사용하여 API Endpoint 생성 및 요청
            let endpoint = AuthEndpoint.serverLogin(requestDTO)
            let responseDTO: AuthResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 3. 응답받은 Data 모델(AuthResponseDTO)을 Domain 모델(AuthInfo)로 변환하여 반환
            return responseDTO.toDomain()
            
        } catch let error as NetworkError {
            throw mapToDomainError(from: error)
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                appleSignInContinuation?.resume(throwing: DomainError.missingProfileData)
                return
            }
            
            let user = SNSUser(
                accessToken: tokenString,
                snsProvider: .apple
            )
            appleSignInContinuation?.resume(returning: user)
        } else {
            appleSignInContinuation?.resume(throwing: DomainError.unknown("Apple credential is not AppleIDCredential."))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = mapToDomainError(from: error, provider: .apple)
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
            throw DomainError.cannotFindRootViewController
        }
        return rootViewController
    }
    
    private func mapToSnsUser(from gidUser: GIDGoogleUser) throws -> Domain.SNSUser {
        guard let idToken = gidUser.idToken?.tokenString else {
            throw DomainError.missingProfileData
        }
        return Domain.SNSUser(
            accessToken: idToken,
            snsProvider: .google
        )
    }
    
    // MARK: - Error Mapping
    
    private func mapToDomainError(from error: Error, provider: SNSProvider? = nil) -> DomainError {
        Logger.network.error("Original Auth Error from \(provider?.rawValue ?? "nil"): \(error)")
        
        // --- NetworkError 매핑 ---
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection, .timeout:
                return .networkUnavailable
            case .decodingError:
                return .dataParsingFailed
            case .statusCodeError(_, let response):
                return .serverError(message: response?.message)
            default:
                return .unknown("네트워크 오류: \(networkError.localizedDescription)")
            }
        }
        
        // --- Google 에러 매핑 ---
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
