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
    func clear()
}

public final class DefaultTokenStorage: TokenStorage {
    public init() {}
    
    private var service: String {
        return Bundle.main.bundleIdentifier ?? "com.jiujitsulab.connect"
    }
    
    public func save(accessToken: String, refreshToken: String, provider: String) {
        saveToKeychain(key: "accessToken", value: accessToken)
        saveToKeychain(key: "refreshToken", value: refreshToken)
        UserDefaults.standard.set(provider, forKey: "snsProvider")
    }
    
    public func getAccessToken() -> String? {
        return readFromKeychain(key: "accessToken")
    }
    
    public func getRefreshToken() -> String? {
        return readFromKeychain(key: "refreshToken")
    }
    
    public func clear() {
        deleteFromKeychain(key: "accessToken")
        deleteFromKeychain(key: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "snsProvider")
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
