//
//  AuthRepositoryImpl.swift
//  JiuJitsuConnect
//
//  Created by suni on 9/21/25.
//

import Foundation
import Domain
import GoogleSignIn
import UIKit

public final class AuthRepositoryImpl: AuthRepository {
    
    public init() {}
    
    @MainActor
    public func signInWithGoogle() async throws -> Domain.SNSUser {
        let rootViewController = try findRootViewController()
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        return try mapToSnsUser(from: result.user)
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
}
