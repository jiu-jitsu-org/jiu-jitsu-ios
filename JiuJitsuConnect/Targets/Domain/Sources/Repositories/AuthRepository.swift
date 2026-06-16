//
//  AuthRepository.swift
//  Domain
//
//  Created by suni on 9/21/25.
//

import Foundation

public protocol AuthRepository: Sendable {
    func signInWithGoogle() async throws -> SNSUser
    func signInWithApple() async throws -> SNSUser
    func signInWithKakao() async throws -> SNSUser
    func signOut() async
    
    func serverLogin(user: SNSUser) async throws -> AuthInfo
    func serverLogout() async throws -> Bool
    
    func autoLogin() async throws -> AuthInfo?
    func hasValidToken() -> Bool

    /// 저장된 refresh 토큰으로 세션을 갱신하고 새 accessToken을 반환한다(single-flight).
    /// 웹뷰가 자기 토큰 만료 시 네이티브에 갱신을 위임할 때 사용한다.
    func refreshSession() async throws -> String
}
