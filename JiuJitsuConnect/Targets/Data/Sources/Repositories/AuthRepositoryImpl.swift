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
/// `appleSignInContinuation`·`appleAuthCodeContinuation`은 `@MainActor` 메서드
/// (`signInWithApple` / `appleAuthorizationCodeForWithdrawal`)에서 설정되고
/// 동일 메인 스레드에서 발화하는 delegate 콜백(`authorizationController(...)`)에서만 접근하므로
/// 외부 동시성 경계에서 안전하다.
public final class AuthRepositoryImpl: NSObject, AuthRepository, ASAuthorizationControllerDelegate, @unchecked Sendable {

    private let networkService: NetworkService
    private let tokenStorage: TokenStorage

    private var appleSignInContinuation: CheckedContinuation<SNSUser, Error>?
    /// 탈퇴 재인증(`appleAuthorizationCodeForWithdrawal`) 전용 continuation.
    /// 로그인용(`appleSignInContinuation`)과 같은 delegate를 공유하므로, 둘 중 하나만 동시에 살아 있다.
    private var appleAuthCodeContinuation: CheckedContinuation<String, Error>?
    /// 스플래시가 10초에 끊어 둔 자동 로그인이 도는 중에 [다시 시도]가 새로 시작하면, 늦게 끝난 쪽이
    /// 회전된 refresh 토큰을 덮어 다음 자동 로그인이 깨진다. 진행 중이면 그 요청에 합류한다(#367).
    private let autoLoginInFlight = AutoLoginInFlight()
    /// `presentationContextProvider`는 weak라 요청이 끝날 때까지 여기서 붙잡아 둔다.
    private var applePresentationContext: ApplePresentationContext?
    
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
        // 인스턴스를 앱 전체가 공유하므로, 진행 중인 요청 위에 새 요청을 겹치면 continuation이 덮어써져
        // 두 컨트롤러의 콜백이 같은 continuation을 두 번 resume해 크래시한다(#87). 진행 중이면 새 요청은 취소로 끝낸다.
        guard appleSignInContinuation == nil else {
            Log.trace("Apple sign-in already in progress — ignoring duplicate request", category: .debug, level: .info)
            throw DomainError.signInCancelled
        }
        let presentationContext = try makeApplePresentationContext()
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            self.applePresentationContext = presentationContext
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = []
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = presentationContext
            authorizationController.performRequests()
        }
    }
    
    public func storedProvider() -> SNSProvider? {
        SNSProvider(rawValue: tokenStorage.getProvider() ?? "")
    }

    /// 탈퇴 시점에 Apple 재인증으로 **새 authorizationCode**를 발급받는다.
    /// 로그인 때 받은 code는 이미 만료되어 서버의 Apple 토큰 revoke에 쓸 수 없다(#41, BE #149).
    /// provider가 Apple이 아니면 재인증 창을 띄우지 않고 nil을 반환해 기존 탈퇴 경로를 그대로 탄다.
    @MainActor
    public func appleAuthorizationCodeForWithdrawal() async throws -> String? {
        guard storedProvider() == .apple else {
            return nil
        }
        // 로그인/재인증 요청은 같은 delegate·continuation을 공유하므로, 진행 중이면 겹치지 않게 막는다(#87).
        guard appleSignInContinuation == nil, appleAuthCodeContinuation == nil else {
            Log.trace("Apple auth already in progress — ignoring withdrawal re-auth", category: .debug, level: .info)
            throw DomainError.signInCancelled
        }
        let presentationContext = try makeApplePresentationContext()
        return try await withCheckedThrowingContinuation { continuation in
            self.appleAuthCodeContinuation = continuation
            self.applePresentationContext = presentationContext

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = []

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = presentationContext
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
    
    public func serverLogout(fcmToken: String?) async throws -> Bool {
        do {
            guard let accessToken = tokenStorage.getAccessToken(),
                  let refreshToken = tokenStorage.getRefreshToken() else {
                return false
            }
            
            let requestDTO = LogoutRequestDTO(
                accessToken: accessToken,
                refreshToken: refreshToken,
                fcmToken: fcmToken
            )
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
        try await autoLoginInFlight.run { [self] in try await performAutoLogin() }
    }

    private func performAutoLogin() async throws -> AuthInfo? {
        // 자동 로그인 불가 경로에서는 남은 토큰을 모두 지운다. accessToken만 남으면
        // 게스트 상태의 이후 요청(로그인 포함)에 만료 토큰이 실려 A0003으로 계속 거부된다.
        // 1. 자동 로그인 설정 확인
        guard tokenStorage.isAutoLoginEnabled() else {
            tokenStorage.clear()
            return nil
        }
        
        // 2. 저장된 토큰 확인
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            tokenStorage.clear()
            return nil
        }
        
        do {
            // 3. Refresh Token으로 새 Access Token 발급
            let requestDTO = RefreshRequestDTO(refreshToken: refreshToken)
            let endpoint = AuthEndpoint.refresh(requestDTO)
            let responseDTO: RefreshResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 4. 기다리는 사이(스플래시 대기 초과 뒤 로그인 · 로그아웃) 세션이 바뀌었으면 결과를 버린다(#372).
            //    저장하면 새 계정 토큰을 이전 계정 토큰으로 덮는다.
            guard tokenStorage.getRefreshToken() == refreshToken else {
                Log.trace("자동 로그인 응답이 바뀐 세션에 도착 → 저장하지 않음", category: .network, level: .info)
                return nil
            }

            // 5. 새 토큰 저장
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
            let domainError = error.toDomainError()
            // refresh 토큰 만료 = 세션 완전 종료, 재시도 불가이므로 저장된 토큰을 즉시 정리한다.
            // 그사이 다른 계정으로 로그인했으면 그 토큰까지 지우지 않는다(#372).
            if case .apiError(let code, _) = domainError,
               code.endsSession,
               tokenStorage.getRefreshToken() == refreshToken {
                tokenStorage.clear()
            }
            throw domainError
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func hasValidToken() -> Bool {
        return tokenStorage.getAccessToken() != nil &&
               tokenStorage.getRefreshToken() != nil &&
               tokenStorage.isAutoLoginEnabled()
    }

    public func storedAccessToken() -> String? {
        // 자동 로그인이 돌 조건(hasValidToken)일 때만 돌려준다 — 아니면 autoLogin이 토큰을 지운다.
        guard hasValidToken() else { return nil }
        return tokenStorage.getAccessToken()
    }

    public func refreshSession() async throws -> String {
        // 실제 갱신은 NetworkService의 single-flight 코디네이터가 수행한다(401 인터셉터와 공유).
        // refresh 토큰이 회전되므로 인터셉터·웹 위임이 같은 코디네이터를 타야 경쟁이 없다.
        do {
            return try await networkService.refreshSession()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            resumeActiveAppleRequest(with: DomainError.unknown("Apple credential is not AppleIDCredential."))
            return
        }

        // 탈퇴 재인증 경로: identityToken이 아니라 서버 revoke용 authorizationCode가 필요하다.
        if appleAuthCodeContinuation != nil {
            guard let authorizationCode = appleIDCredential.authorizationCode,
                  let code = String(data: authorizationCode, encoding: .utf8) else {
                resumeAppleAuthCode(with: .failure(DomainError.missingProfileData))
                return
            }
            resumeAppleAuthCode(with: .success(code))
            return
        }

        // 로그인 경로
        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            resumeAppleSignIn(with: .failure(DomainError.missingProfileData))
            return
        }

        let user = SNSUser(
            accessToken: tokenString,
            snsProvider: .apple
        )
        resumeAppleSignIn(with: .success(user))
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = AuthErrorMapper.map(from: error, provider: .apple)
        resumeActiveAppleRequest(with: authError)
    }

    /// 로그인/탈퇴 재인증 중 살아 있는 쪽 continuation을 실패로 resume한다.
    private func resumeActiveAppleRequest(with error: Error) {
        if appleAuthCodeContinuation != nil {
            resumeAppleAuthCode(with: .failure(error))
        } else {
            resumeAppleSignIn(with: .failure(error))
        }
    }

    /// continuation을 비운 뒤 resume한다. 비우지 않으면 다음 요청이 진행 중으로 오인되고,
    /// 늦게 온 콜백이 이미 끝난 continuation을 다시 resume할 수 있다.
    private func resumeAppleSignIn(with result: Result<SNSUser, Error>) {
        guard let continuation = appleSignInContinuation else { return }
        appleSignInContinuation = nil
        applePresentationContext = nil
        continuation.resume(with: result)
    }

    /// `appleAuthCodeContinuation`도 동일하게 비운 뒤 resume한다(이중 resume 방지).
    private func resumeAppleAuthCode(with result: Result<String, Error>) {
        guard let continuation = appleAuthCodeContinuation else { return }
        appleAuthCodeContinuation = nil
        applePresentationContext = nil
        continuation.resume(with: result)
    }
    
    // MARK: - Apple 창 기준 window

    /// `presentationAnchor`는 옵셔널을 돌려줄 수 없어, 요청 전에 window를 정하고 못 정하면 요청하지 않는다(#378).
    /// 제어 센터 · 시스템 알럿이 떠 있으면 key window가 없을 수 있어 순서대로 물러선다:
    /// 활성 장면의 key window → 아무 장면의 window → 장면으로 새 window.
    @MainActor
    private func makeApplePresentationContext() throws -> ApplePresentationContext {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes.first { $0.activationState == .foregroundActive }
        if let keyWindow = activeScene?.windows.first(where: { $0.isKeyWindow })
            ?? windowScenes.lazy.flatMap(\.windows).first {
            return ApplePresentationContext(anchor: keyWindow)
        }
        guard let scene = activeScene ?? windowScenes.first else {
            Log.trace("Apple sign-in: no window scene to present from", category: .system, level: .error)
            throw DomainError.cannotFindRootViewController
        }
        return ApplePresentationContext(anchor: UIWindow(windowScene: scene))
    }
    
    public func signOut() async {
        // 서버 로그아웃 실패·세션 만료 경로도 이 메서드로 로컬 로그아웃하므로, 서버 결과와 무관하게
        // 로컬 토큰을 정리해야 게스트 상태에 만료 토큰이 남지 않는다.
        tokenStorage.clear()

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

// MARK: - ApplePresentationContext

/// 요청을 시작할 때 정한 window를 그대로 돌려준다.
private final class ApplePresentationContext: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        anchor
    }
}

// MARK: - AutoLoginInFlight

/// 진행 중인 자동 로그인 하나를 들고 있다가, 겹쳐 온 호출을 그 결과에 합류시킨다.
private actor AutoLoginInFlight {
    private var task: Task<AuthInfo?, Error>?

    func run(_ operation: @Sendable @escaping () async throws -> AuthInfo?) async throws -> AuthInfo? {
        if let task {
            return try await task.value
        }
        let task = Task { try await operation() }
        self.task = task
        defer { self.task = nil }
        return try await task.value
    }
}
