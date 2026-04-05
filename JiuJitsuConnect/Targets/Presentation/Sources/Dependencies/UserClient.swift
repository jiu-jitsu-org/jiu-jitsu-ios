//
//  UserClient.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/1/25.
//

import ComposableArchitecture
import Domain
import UIKit

// MARK: - API Client Interface
public struct UserClient {
    public var signup: @Sendable (Domain.SignupInfo) async throws -> Domain.AuthInfo // 회원 가입
    public var checkNickname: @Sendable (Domain.CheckNicknameInfo) async throws -> Bool // 닉네임 중복 체크
    public var withdrawal: @Sendable () async throws -> Bool // 회원 탈퇴
    /// 회원 앱 정보 등록 (`/api/user/appInfo`)
    public var registerAppInfo: @Sendable (AppInfo) async throws -> Void
    /// 로그인 등 이후 FCM 토큰만 갱신해 동일 API로 재등록
    public var updateFCMToken: @Sendable (String) async throws -> Void

    public init(
        signup: @Sendable @escaping (Domain.SignupInfo) async throws -> Domain.AuthInfo,
        checkNickname: @Sendable @escaping (Domain.CheckNicknameInfo) async throws -> Bool,
        withdrawal: @Sendable @escaping () async throws -> Bool,
        registerAppInfo: @Sendable @escaping (AppInfo) async throws -> Void,
        updateFCMToken: @Sendable @escaping (String) async throws -> Void
    ) {
        self.signup = signup
        self.checkNickname = checkNickname
        self.withdrawal = withdrawal
        self.registerAppInfo = registerAppInfo
        self.updateFCMToken = updateFCMToken
    }
}

// MARK: - Live Implementation
extension UserClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = Self(
        signup: { _ in
            Domain.AuthInfo(accessToken: nil,
                            refreshToken: nil,
                            tempToken: "test-temp-token",
                            isNewUser: true,
                            userInfo: nil)
        },
        checkNickname: { _ in
            true
        },
        withdrawal: {
            true
        },
        registerAppInfo: { _ in },
        updateFCMToken: { _ in }
    )
}

// MARK: - Dependency Injection
public extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

extension UserClient {
    static let unimplemented: Self = Self(
        signup: { _ in
            fatalError("unimplemented.signup is not implemented")
        },
        checkNickname: { _ in
            fatalError("unimplemented.checkNickname is not implemented")
        },
        withdrawal: {
            fatalError("unimplemented.withdrawal is not implemented")
        },
        registerAppInfo: { _ in
            fatalError("unimplemented.registerAppInfo is not implemented")
        },
        updateFCMToken: { _ in
            fatalError("unimplemented.updateFCMToken is not implemented")
        }
    )
}

// MARK: - 현재 기기 기준 `AppInfo` (서버 4필드만 사용)
public extension AppInfo {
    /// Swagger `osType` 예시(`IOS`)에 맞춘 기본값
    @MainActor
    static func makeWithCurrentDevice(fcmToken: String, osType: String = "IOS") -> AppInfo {
        AppInfo(
            fcmToken: fcmToken,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            osType: osType,
            osVersion: UIDevice.current.systemVersion
        )
    }
}
