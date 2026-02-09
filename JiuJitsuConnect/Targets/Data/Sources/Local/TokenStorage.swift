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
    func clear()

    func setAutoLoginEnabled(_ enabled: Bool)
    func isAutoLoginEnabled() -> Bool
}

public final class DefaultTokenStorage: TokenStorage {
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let provider = "provider"
        static let autoLoginEnabled = "autoLoginEnabled"
    }
    
    public init() {}
    
    private var service: String {
        return Bundle.main.bundleIdentifier ?? "com.jiujitsulab.connect"
    }
    
    public func save(accessToken: String, refreshToken: String, provider: String) {
        setAutoLoginEnabled(true)
        saveToKeychain(key: Keys.accessToken, value: accessToken)
        saveToKeychain(key: Keys.refreshToken, value: refreshToken)
        UserDefaults.standard.set(provider, forKey: Keys.provider)
    }
    
    public func getAccessToken() -> String? {
        return readFromKeychain(key: Keys.accessToken)
    }
    
    public func getRefreshToken() -> String? {
        return readFromKeychain(key: Keys.refreshToken)
    }
    
    public func getProvider() -> String? {
        return UserDefaults.standard.string(forKey: Keys.provider)
    }
    
    public func clear() {
        deleteFromKeychain(key: Keys.accessToken)
        deleteFromKeychain(key: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.provider)
        UserDefaults.standard.removeObject(forKey: Keys.autoLoginEnabled)
    }
    
    // MARK: - Auto Login
    public func setAutoLoginEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.autoLoginEnabled)
    }
    
    public func isAutoLoginEnabled() -> Bool {
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
