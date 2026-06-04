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
    /// 사용자 프로필 조회 (GET `/api/user/profile`) — 관장사범 인증 상태(ownerRequested) 등 포함
    public var fetchUserProfile: @Sendable () async throws -> UserProfile
    /// 회원 앱 정보 등록 (`/api/user/appInfo`)
    public var registerAppInfo: @Sendable (AppInfo) async throws -> Void
    /// 로그인 등 이후 FCM 토큰만 갱신해 동일 API로 재등록
    public var updateFCMToken: @Sendable (String) async throws -> Void
    /// 닉네임 단독 수정 (PUT `/api/user/profile/nickname`).
    public var updateNickname: @Sendable (_ nickname: String) async throws -> Void
    /// 프로필 이미지 설정 (PUT `/api/user/profile/image`).
    ///
    /// 서버 등록(`POST /api/image`)으로 발급된 이미지 파일 id를 전달한다.
    /// (삭제는 `imageClient.deleteImage(id:)` 경로 사용.)
    public var setProfileImage: @Sendable (_ imageFileId: Int64) async throws -> Void
    /// 관장/사범 인증 요청 (PUT `/api/user/owner`).
    ///
    /// 서버 등록으로 발급된 인증 이미지 파일 id를 전달해 권한 요청을 등록한다.
    public var requestOwnerVerification: @Sendable (_ imageFileId: Int64) async throws -> Void

    public init(
        signup: @Sendable @escaping (Domain.SignupInfo) async throws -> Domain.AuthInfo,
        checkNickname: @Sendable @escaping (Domain.CheckNicknameInfo) async throws -> Bool,
        withdrawal: @Sendable @escaping () async throws -> Bool,
        fetchUserProfile: @Sendable @escaping () async throws -> UserProfile,
        registerAppInfo: @Sendable @escaping (AppInfo) async throws -> Void,
        updateFCMToken: @Sendable @escaping (String) async throws -> Void,
        updateNickname: @Sendable @escaping (String) async throws -> Void,
        setProfileImage: @Sendable @escaping (Int64) async throws -> Void,
        requestOwnerVerification: @Sendable @escaping (Int64) async throws -> Void
    ) {
        self.signup = signup
        self.checkNickname = checkNickname
        self.withdrawal = withdrawal
        self.fetchUserProfile = fetchUserProfile
        self.registerAppInfo = registerAppInfo
        self.updateFCMToken = updateFCMToken
        self.updateNickname = updateNickname
        self.setProfileImage = setProfileImage
        self.requestOwnerVerification = requestOwnerVerification
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
        fetchUserProfile: {
            UserProfile(
                userId: 1,
                email: "user@example.com",
                nickname: "홍길동",
                profileImageUrl: nil,
                snsProvider: "KAKAO",
                ownerRequested: false,
                ownerRequestImageUrl: nil,
                role: "USER",
                status: "ACTIVE"
            )
        },
        registerAppInfo: { _ in },
        updateFCMToken: { _ in },
        updateNickname: { _ in },
        setProfileImage: { _ in },
        requestOwnerVerification: { _ in }
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
        fetchUserProfile: {
            fatalError("unimplemented.fetchUserProfile is not implemented")
        },
        registerAppInfo: { _ in
            fatalError("unimplemented.registerAppInfo is not implemented")
        },
        updateFCMToken: { _ in
            fatalError("unimplemented.updateFCMToken is not implemented")
        },
        updateNickname: { _ in
            fatalError("unimplemented.updateNickname is not implemented")
        },
        setProfileImage: { _ in
            fatalError("unimplemented.setProfileImage is not implemented")
        },
        requestOwnerVerification: { _ in
            fatalError("unimplemented.requestOwnerVerification is not implemented")
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
