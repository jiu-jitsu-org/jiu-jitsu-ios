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

/// @unchecked Sendable 사유: Apple Sign-In delegate 채택을 위해 NSObject 상속이 강제되며,
/// `appleSignInContinuation`은 `@MainActor` 메서드(`signInWithApple`)에서 설정되고
/// 동일 메인 스레드에서 발화하는 delegate 콜백(`authorizationController(...)`)에서만 접근하므로
/// 외부 동시성 경계에서 안전하다.
public final class AuthRepositoryImpl: NSObject, AuthRepository, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, @unchecked Sendable {
    
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
                    self?.handleKakaoResponse(oauthToken: oauthToken, error: error, continuation: continuation)
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
        #if targetEnvironment(simulator)
        // 시뮬레이터에서는 Google/Apple SNS 로그인 SDK가 정상 동작하지 않아 수동 로그인이 불가능하다.
        // 개발 편의를 위해 저장된 refreshToken이 없을 때만 디버그용 토큰을 시드하고, 이후는
        // 기존 자동로그인(refresh) 플로우를 그대로 태운다. (첫 refresh 성공 시 회전된 토큰이
        // Keychain에 저장되므로 시드 토큰은 1회만 사용된다.) 토큰 만료 시 아래 상수만 갱신한다.
        seedSimulatorDebugTokenIfNeeded()
        #endif

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
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // 절대 도달하지 않는 경로
            fatalError("No active window found for Apple Sign In")
        }
        return window
    }
    
    public func signOut() async {
        await MainActor.run {
            GIDSignIn.sharedInstance.signOut()
        }
        
        guard AuthApi.hasToken() else { return }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UserApi.shared.logout { _ in
                continuation.resume()
            }
        }
    }
    
    // MARK: - Private Methods

    #if targetEnvironment(simulator)
    /// 시뮬레이터 자동로그인용 디버그 provider. refreshToken은 `Configs/Secrets.xcconfig`의
    /// `SIMULATOR_DEBUG_REFRESH_TOKEN`(gitignore) → Info.plist 경로로 주입받는다(`BASE_URL` 동일 패턴).
    private enum SimulatorDebugAuth {
        static let provider = "GOOGLE"

        static var refreshToken: String? {
            let token = Bundle.main.object(forInfoDictionaryKey: "SIMULATOR_DEBUG_REFRESH_TOKEN") as? String
            // Beta/Release 빌드는 빈 문자열로 주입되므로 nil 취급한다.
            return (token?.isEmpty == false) ? token : nil
        }
    }

    private func seedSimulatorDebugTokenIfNeeded() {
        guard tokenStorage.getRefreshToken() == nil else { return }
        guard let refreshToken = SimulatorDebugAuth.refreshToken else {
            Log.trace("🧪 시뮬레이터 디버그 토큰 미설정 — Secrets.xcconfig의 SIMULATOR_DEBUG_REFRESH_TOKEN 확인", category: .storage, level: .info)
            return
        }
        Log.trace("🧪 시뮬레이터 디버그 토큰 시드 — SNS 로그인 우회 자동로그인 진행", category: .debug, level: .info)
        // accessToken은 직후 refresh 호출로 즉시 교체되므로 refreshToken을 임시값으로 채운다.
        tokenStorage.save(
            accessToken: refreshToken,
            refreshToken: refreshToken,
            provider: SimulatorDebugAuth.provider
        )
    }
    #endif

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
