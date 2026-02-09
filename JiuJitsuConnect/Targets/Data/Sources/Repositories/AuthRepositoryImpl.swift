//
//  AuthRepositoryImpl.swift
//  Data
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
    private let tokenStorage: TokenStorage

    private var appleSignInContinuation: CheckedContinuation<SNSUser, Error>?
    
    public init(networkService: NetworkService = DefaultNetworkService(),
                tokenStorage: TokenStorage = DefaultTokenStorage(),
                appleSignInContinuation: CheckedContinuation<SNSUser, Error>? = nil) {
        self.networkService = networkService
        self.tokenStorage = tokenStorage
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
            throw AuthErrorMapper.map(from: error, provider: .google)
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
                    UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                        self?.handleKakaoResponse(oauthToken: oauthToken, error: error, continuation: continuation)
                    }
                }
            } else {
                // 카카오 계정(웹뷰)으로 로그인 시도
                UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                    self?.handleKakaoResponse(oauthToken: oauthToken, error: error, continuation: continuation)
                }
            }
        }
    }
    
    // 중복되는 카카오 응답 처리 로직을 메서드로 추출하여 정리
    private func handleKakaoResponse(oauthToken: OAuthToken?, error: Error?, continuation: CheckedContinuation<SNSUser, Error>) {
        if let error = error {
            let authError = AuthErrorMapper.map(from: error, provider: .kakao)
            continuation.resume(throwing: authError)
        } else if let oauthToken = oauthToken {
            let snsUser = Domain.SNSUser(
                accessToken: oauthToken.accessToken,
                snsProvider: .kakao
            )
            continuation.resume(returning: snsUser)
        } else {
            let authError = AuthErrorMapper.map(
                from: DomainError.unknown("Kakao login failed with no token and no error."),
                provider: .kakao
            )
            continuation.resume(throwing: authError)
        }
    }
    
    // MARK: - API
    
    public func serverLogin(user: SNSUser) async throws -> AuthInfo {
        do {
            // 1. Domain 모델(SNSUser)을 Data 모델(LoginRequestDTO)로 변환
            let requestDTO = LoginRequestDTO(user: user)
            
            // 2. 변환된 DTO를 사용하여 API Endpoint 생성 및 요청
            let endpoint = AuthEndpoint.serverLogin(requestDTO)
            let responseDTO: LoginResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 로그인 성공 시 토큰 저장
            if let accessToken = responseDTO.accessToken, let refreshToken = responseDTO.refreshToken {
                tokenStorage.save(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    provider: user.snsProvider.rawValue
                )
            }
            
            // 3. 응답받은 Data 모델(LoginResponseDTO)을 Domain 모델(AuthInfo)로 변환하여 반환
            return responseDTO.toDomain()
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    public func serverLogout() async throws -> Bool {
        do {
            guard let accessToken = tokenStorage.getAccessToken(),
                  let refreshToken = tokenStorage.getRefreshToken() else {
                return false
            }
            
            let requestDTO = LogoutRequestDTO(accessToken: accessToken, refreshToken: refreshToken)
            let endpoint = AuthEndpoint.serverLogout(requestDTO)
            let responseDTO: SuccessResponseDTO = try await networkService.request(endpoint: endpoint)
            
            if responseDTO.success {
                tokenStorage.clear()
            }
            
            return responseDTO.success
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Auto Login

    public func autoLogin() async throws -> AuthInfo? {
        // 1. 자동 로그인 설정 확인
        guard tokenStorage.isAutoLoginEnabled() else {
            return nil
        }
        
        // 2. 저장된 토큰 확인
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            tokenStorage.setAutoLoginEnabled(false)
            return nil
        }
        
        do {
            // 3. Refresh Token으로 새 Access Token 발급
            let requestDTO = RefreshRequestDTO(refreshToken: refreshToken)
            let endpoint = AuthEndpoint.refresh(requestDTO)
            let responseDTO: RefreshResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 4. 새 토큰 저장
            if let accessToken = responseDTO.accessToken,
               let refreshToken = responseDTO.refreshToken,
               let provider = tokenStorage.getProvider() {
                tokenStorage.save(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    provider: provider
                )
            }
            return responseDTO.toDomain()
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func hasValidToken() -> Bool {
        return tokenStorage.getAccessToken() != nil &&
               tokenStorage.getRefreshToken() != nil &&
               tokenStorage.isAutoLoginEnabled()
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
        let authError = AuthErrorMapper.map(from: error, provider: .apple)
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
    
}
