//
//  NicknameValidationClient.swift
//  Presentation
//
//  Created by suni on 10/6/25.
//

import ComposableArchitecture
import Domain

// MARK: - API Client Interface
@DependencyClient
public struct NicknameValidationClient {
    /// Checks if a nickname is available.
    public var isAvailable: @Sendable (_ nickname: String) async throws -> Bool
}

// MARK: - Live Implementation
extension NicknameValidationClient: DependencyKey {
    public static let liveValue = Self(
        isAvailable: { nickname in
            // TODO: - 닉네임 설정 API
            // 예시: 2초 후, "뿌리뿌리대마왕" 이라는 닉네임만 중복이라고 가정
            try await Task.sleep(for: .seconds(0.5))
            if nickname == "뿌리뿌리대마왕" {
                return false
            } else {
                return true
            }
        }
    )
}

// MARK: - Dependency Injection
extension DependencyValues {
    public var nicknameValidationClient: NicknameValidationClient {
        get { self[NicknameValidationClient.self] }
        set { self[NicknameValidationClient.self] = newValue }
    }
}
