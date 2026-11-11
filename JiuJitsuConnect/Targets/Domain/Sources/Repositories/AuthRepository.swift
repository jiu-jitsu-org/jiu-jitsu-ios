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

    /// 탈퇴 시점에 Apple 재인증으로 **새 authorizationCode**를 발급받아 반환한다.
    /// 서버가 Apple 토큰 revoke에 쓰며, 로그인 때 받은 code는 이미 만료되어 쓸 수 없다(#41, BE #149).
    /// 현재 로그인 provider가 Apple이 아니면 재인증 없이 `nil`을 반환한다(카카오/구글은 iOS 작업 불필요).
    func appleAuthorizationCodeForWithdrawal() async throws -> String?
    
    func serverLogin(user: SNSUser) async throws -> AuthInfo
    func serverLogout() async throws -> Bool
    
    func autoLogin() async throws -> AuthInfo?
    func hasValidToken() -> Bool

    /// 자동 로그인 대상일 때 기기에 저장된 access token. 만료 여부는 보지 않는다.
    /// 자동 로그인(refresh)을 기다리지 않고 홈 피드를 미리 불러 둘 때 쓴다(#270).
    func storedAccessToken() -> String?

    /// 저장된 refresh 토큰으로 세션을 갱신하고 새 accessToken을 반환한다(single-flight).
    /// 웹뷰가 자기 토큰 만료 시 네이티브에 갱신을 위임할 때 사용한다.
    func refreshSession() async throws -> String
}
