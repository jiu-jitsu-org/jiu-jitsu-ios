//
//  TokenStorage.swift
//  Data
//
//  Created by suni on 12/7/25.
//

import Foundation
import Security

public protocol TokenStorage: Sendable {
    func save(accessToken: String, refreshToken: String, provider: String)
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getProvider() -> String?
    /// 토큰을 지운다. 마지막 로그인 수단(`getLastLoginProvider`)은 남긴다 — 로그아웃 · 세션 만료 뒤
    /// 로그인 화면이 "최근 로그인"을 보여 줘야 한다(#380).
    func clear()

    /// 이 기기에서 마지막으로 로그인에 성공한 SNS 종류(#380). `clear()`로는 지워지지 않는다.
    func getLastLoginProvider() -> String?
    /// 로그인 · 가입 완료에서만 부른다. 토큰 갱신(`save`)과 나눈 이유: 로그아웃 직후 늦게 끝난 갱신이
    /// 빈 `provider`로 저장해도 마지막 로그인 수단이 지워지지 않게 한다.
    func recordLastLoginProvider(_ provider: String)
    /// 탈퇴처럼 이 기기에서 계정을 정리할 때만 지운다(#380).
    func clearLastLoginProvider()

    func setAutoLoginEnabled(_ enabled: Bool)
    func isAutoLoginEnabled() -> Bool
}

public final class DefaultTokenStorage: TokenStorage {

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let provider = "provider"
        /// `provider`는 세션과 함께 지워지므로 따로 둔다(#380).
        static let lastLoginProvider = "lastLoginProvider"
        static let autoLoginEnabled = "autoLoginEnabled"
    }

    /// `SecItemDelete` → `SecItemAdd` 같은 다단계 Keychain 작업을 직렬화하기 위한 잠금.
    /// `save()` 내부에서 `setAutoLoginEnabled`를 호출하므로 재귀 잠금이 필요하다.
    private let lock = NSRecursiveLock()

    public init() {}

    private var service: String {
        return Bundle.main.bundleIdentifier ?? "com.jiujitsulab.connect"
    }

    public func save(accessToken: String, refreshToken: String, provider: String) {
        lock.lock()
        defer { lock.unlock() }
        setAutoLoginEnabled(true)
        saveToKeychain(key: Keys.accessToken, value: accessToken)
        saveToKeychain(key: Keys.refreshToken, value: refreshToken)
        UserDefaults.standard.set(provider, forKey: Keys.provider)
    }

    public func getAccessToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return readFromKeychain(key: Keys.accessToken)
    }

    public func getRefreshToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return readFromKeychain(key: Keys.refreshToken)
    }

    public func getProvider() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.string(forKey: Keys.provider)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        deleteFromKeychain(key: Keys.accessToken)
        deleteFromKeychain(key: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.provider)
        UserDefaults.standard.removeObject(forKey: Keys.autoLoginEnabled)
    }

    // MARK: - Last Login Provider (#380)
    public func getLastLoginProvider() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.string(forKey: Keys.lastLoginProvider)
    }

    public func recordLastLoginProvider(_ provider: String) {
        guard !provider.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.set(provider, forKey: Keys.lastLoginProvider)
    }

    public func clearLastLoginProvider() {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.removeObject(forKey: Keys.lastLoginProvider)
    }

    // MARK: - Auto Login
    public func setAutoLoginEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.set(enabled, forKey: Keys.autoLoginEnabled)
    }

    public func isAutoLoginEnabled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.bool(forKey: Keys.autoLoginEnabled)
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)

        // 1. 기존 데이터 삭제를 위한 쿼리 (ValueData 불필요)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ] as [String: Any]

        // 기존 항목이 있다면 삭제 (Update 대신 Delete -> Add 방식을 많이 사용함)
        SecItemDelete(query as CFDictionary)

        // 2. 새로운 데이터 저장을 위한 쿼리 (ValueData 포함)
        var newAttributes = query
        newAttributes[kSecValueData as String] = data

        // 저장 수행
        SecItemAdd(newAttributes as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,       // 데이터를 리턴받겠다
            kSecMatchLimit: kSecMatchLimitOne // 중복 시 하나만
        ] as [String: Any]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteFromKeychain(key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ] as [String: Any]

        SecItemDelete(query as CFDictionary)
    }
}
