//
//  AuthRepository.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public protocol AuthRepository {
    func signInWithGoogle() async throws -> SNSUser
    func signInWithApple() async throws -> SNSUser
    func signInWithKakao() async throws -> SNSUser
    func signOut() async throws
    
    func serverLogin(user: SNSUser) async throws -> AuthInfo
    func serverLogout() async throws -> Bool
    
    func autoLogin() async throws -> AuthInfo?
    func hasValidToken() -> Bool
}
