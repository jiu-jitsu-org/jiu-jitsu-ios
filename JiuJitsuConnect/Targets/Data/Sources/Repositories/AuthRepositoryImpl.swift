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

public final class AuthRepositoryImpl: NSObject, AuthRepository, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var appleSignInContinuation: CheckedContinuation<SNSUser, Error>?
    
    public init(appleSignInContinuation: CheckedContinuation<SNSUser, Error>? = nil) {
        self.appleSignInContinuation = appleSignInContinuation
    }
    
    @MainActor
    public func signInWithGoogle() async throws -> Domain.SNSUser {
        let rootViewController = try findRootViewController()
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        return try mapToSnsUser(from: result.user)
    }
    
    @MainActor
    public func signInWithApple() async throws -> Domain.SNSUser {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                appleSignInContinuation?.resume(throwing: AuthError.missingProfileData)
                return
            }
            
            let nickname = appleIDCredential.fullName?.formatted() ?? appleIDCredential.email ?? ""
            
            let user = SNSUser(
                id: appleIDCredential.user,
                idToken: tokenString,
                email: appleIDCredential.email ?? "",
                nickname: nickname,
                snsProvider: "APPLE"
            )
            appleSignInContinuation?.resume(returning: user)
        } else {
            appleSignInContinuation?.resume(throwing: AuthError.unknown("Apple credential is not AppleIDCredential."))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            appleSignInContinuation?.resume(throwing: AuthError.signInCancelled)
        } else {
            appleSignInContinuation?.resume(throwing: error)
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // findRootViewController()를 통해 현재 활성화된 window를 반환합니다.
        // 이 메서드는 MainActor에서 호출되므로 try! 사용이 비교적 안전합니다.
        return try! findRootViewController().view.window!
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
        guard let email = gidUser.profile?.email,
              let name = gidUser.profile?.name,
              let idToken = gidUser.idToken?.tokenString else {
            throw AuthError.missingProfileData
        }
        
        return Domain.SNSUser(
            id: gidUser.userID ?? UUID().uuidString,
            idToken: idToken,
            email: email,
            nickname: name,
            snsProvider: "GOOGLE"
        )
    }
    
    public func signOut() async throws {
        await MainActor.run {
            GIDSignIn.sharedInstance.signOut()
            
        }
    }
}
